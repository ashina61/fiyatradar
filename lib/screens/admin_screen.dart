import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../models/product.dart';
import '../services/firebase_service.dart';
import '../state/app_state.dart';
import '../ui/components.dart';
import '../ui/tokens.dart';

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  int tab = 0;
  static const tabs = [
    'Panel',
    'Ürünler',
    'Talepler',
    'Fiyatlar',
    'Doğrulama',
    'Moderasyon',
    'Ayarlar',
  ];

  @override
  Widget build(BuildContext context) {
    final state = AppStateScope.of(context);
    if (!state.isAdmin) {
      return const _AdminUnauthorizedScreen();
    }
    return Scaffold(
      backgroundColor: FR.bg,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
              child: Row(
                children: [
                  FRIconChip(
                    icon: Icons.arrow_back_rounded,
                    onTap: () => Navigator.pop(context),
                  ),
                  const Spacer(),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: FR.gold.withOpacity(.14),
                      borderRadius: FRRad.all(999),
                      border: Border.all(color: FR.goldDeep.withOpacity(.45)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const FRLiveDot(),
                        const SizedBox(width: 6),
                        Text('KONTROL CANLI',
                            style: frOverline(color: FR.gold, size: 9.5)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: FRPageHeader(
                overline: 'FİYATRADAR KONTROL MERKEZİ',
                title: 'Admin',
                italicTail: ' konsolu',
              ),
            ),
            const SizedBox(height: 14),
            SizedBox(
              height: 42,
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                scrollDirection: Axis.horizontal,
                itemCount: tabs.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (_, i) => _TabChip(
                  label: tabs[i],
                  active: tab == i,
                  onTap: () => setState(() => tab = i),
                ),
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
                children: [_buildTab(state)],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTab(AppState state) {
    switch (tab) {
      case 0:
        return _Panel(state: state);
      case 1:
        return _ProductsTab(state: state);
      case 2:
        return _RequestsTab(state: state);
      case 3:
        return _PricesTab(state: state);
      case 4:
        return _VerificationTab(state: state);
      case 5:
        return _ModerationTab(state: state);
      default:
        return _SettingsTab(state: state);
    }
  }
}

class _AdminUnauthorizedScreen extends StatelessWidget {
  const _AdminUnauthorizedScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: FR.bg,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(
            FRSpace.xl,
            FRSpace.m,
            FRSpace.xl,
            FRSpace.xxl - FRSpace.xs,
          ),
          child: Column(
            children: [
              Row(
                children: [
                  FRIconChip(
                    icon: Icons.arrow_back_rounded,
                    onTap: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Expanded(
                child: Center(
                  child: Container(
                    padding: const EdgeInsetsDirectional.fromSTEB(
                      FRSpace.xl,
                      FRSpace.xl,
                      FRSpace.xl,
                      FRSpace.xl,
                    ),
                    decoration: frSurface(radius: FRRad.l),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.lock_outline_rounded, size: 32, color: FR.bad),
                        const SizedBox(height: 10),
                        Text('Yetkin yok', style: frDisplay(24, FontWeight.w700)),
                        const SizedBox(height: 6),
                        Text(
                          'Bu alan yalnızca admin kullanıcılar için erişilebilir.',
                          textAlign: TextAlign.center,
                          style: frText(12.5, FontWeight.w600, color: FR.ink3, height: 1.45),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TabChip extends StatelessWidget {
  const _TabChip({
    required this.label,
    required this.active,
    required this.onTap,
  });
  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: FRRad.all(999),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color: active ? FR.gold : FR.surface,
          borderRadius: FRRad.all(999),
          border: Border.all(color: active ? FR.gold : FR.hairline),
        ),
        child: Text(
          label,
          style: frText(12, FontWeight.w800,
              color: active ? FR.bg : FR.ink2, letter: .2),
        ),
      ),
    );
  }
}

// ─── Panel (runtime aggregates) ─────────────────────────────────────────────

class _Panel extends StatelessWidget {
  const _Panel({required this.state});
  final AppState state;

  @override
  Widget build(BuildContext context) {
    final products = state.products;
    final fresh = state.freshContributionCountLast24h;
    final pending = state.adminPendingEntries.length;
    final disputed = state.adminDisputedEntries.length;
    final verified = state.aggregateVerifiedCount;
    final trust = state.catalogTrustPercent;

    final recent = state.adminRecentEntries.take(4).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
                child: _StatCard(
                    value: '$fresh',
                    label: 'SON 24S KATKI',
                    delta: fresh > 0 ? 'canlı' : 'beklemede',
                    deltaGood: fresh > 0)),
            const SizedBox(width: 10),
            Expanded(
                child: _StatCard(
                    value: '$pending',
                    label: 'İNCELEMEDE',
                    delta: pending > 0 ? 'topluluğa açık' : 'temiz',
                    deltaGood: pending == 0)),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
                child: _StatCard(
                    value: '$verified',
                    label: 'DOĞRULANMIŞ FİYAT',
                    delta: '${products.length} ürün',
                    deltaGood: true)),
            const SizedBox(width: 10),
            Expanded(
                child: _StatCard(
                    value: trust == 0 ? '—' : '%$trust',
                    label: 'KATALOG GÜVENİ',
                    delta: disputed > 0 ? '$disputed ihtilaf' : 'stabil',
                    deltaGood: disputed == 0)),
          ],
        ),
        const SizedBox(height: 18),
        const FRSectionHead(eyebrow: 'CANLI', title: 'Son katkılar'),
        const SizedBox(height: 10),
        if (recent.isEmpty)
          _empty('Topluluktan henüz katkı gelmedi.')
        else
          _rowList([
            for (final r in recent)
              _EntryRow(product: r.$1, entry: r.$2),
          ]),
      ],
    );
  }
}

class _ProductsTab extends StatelessWidget {
  const _ProductsTab({required this.state});
  final AppState state;

  @override
  Widget build(BuildContext context) {
    final products = state.products;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        FRCta(
          label: 'Yeni ürün ekle',
          icon: Icons.add_rounded,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const ProductFormScreen(),
            ),
          ),
        ),
        const SizedBox(height: 16),
        if (products.isEmpty)
          _empty('Henüz ürün yok.')
        else
          _rowList([
            for (final p in products)
              _ProductAdminRow(product: p),
          ]),
      ],
    );
  }
}

class _ProductAdminRow extends StatelessWidget {
  const _ProductAdminRow({required this.product});
  final Product product;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ProductFormScreen(existing: product),
        ),
      ),
      borderRadius: FRRad.all(FRRad.l),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: FR.surface,
          borderRadius: FRRad.all(FRRad.l),
          border: Border.all(color: FR.hairline),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: FR.surfaceHi,
                borderRadius: FRRad.all(12),
                border: Border.all(color: FR.hairline),
              ),
              alignment: Alignment.center,
              child: Text(product.emoji, style: const TextStyle(fontSize: 22)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(product.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: frText(13.5, FontWeight.w800)),
                  Text(
                    '${product.brand} · ${product.unit} · ${product.category}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: frText(11, FontWeight.w600, color: FR.ink3),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '${product.validEntries.length} fiyat · %${product.aggregateTrustPercent} güven',
                    style: frText(10.5, FontWeight.w800, color: FR.gold),
                  ),
                ],
              ),
            ),
            Icon(Icons.edit_outlined, color: FR.ink3, size: 17),
          ],
        ),
      ),
    );
  }
}

class _RequestsTab extends StatelessWidget {
  const _RequestsTab({required this.state});
  final AppState state;

  @override
  Widget build(BuildContext context) {
    final pending =
        state.productRequests.where((r) => r.isPending).toList();
    final decided =
        state.productRequests.where((r) => !r.isPending).take(20).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const FRSectionHead(eyebrow: 'BEKLEYEN', title: 'Onay bekleyen talepler'),
        const SizedBox(height: 10),
        if (pending.isEmpty)
          _empty('Bekleyen talep yok.')
        else
          _rowList([
            for (final r in pending)
              _RequestRow(request: r, state: state),
          ]),
        const SizedBox(height: 18),
        const FRSectionHead(
          eyebrow: 'GEÇMİŞ',
          title: 'Onaylanmış / reddedilmiş talepler',
        ),
        const SizedBox(height: 10),
        if (decided.isEmpty)
          _empty('Henüz karar verilmiş talep yok.')
        else
          _rowList([
            for (final r in decided)
              _RequestRow(request: r, state: state, readOnly: true),
          ]),
      ],
    );
  }
}

class _RequestRow extends StatelessWidget {
  const _RequestRow({
    required this.request,
    required this.state,
    this.readOnly = false,
  });
  final ProductRequest request;
  final AppState state;
  final bool readOnly;

  Color get _statusColor {
    switch (request.status) {
      case 'approved':
        return FR.good;
      case 'rejected':
        return FR.bad;
      default:
        return FR.warn;
    }
  }

  String get _statusLabel {
    switch (request.status) {
      case 'approved':
        return 'Onaylandı';
      case 'rejected':
        return 'Reddedildi';
      default:
        return 'Bekliyor';
    }
  }

  Future<void> _approve(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      await state.adminApproveRequest(req: request);
      messenger.showSnackBar(
        SnackBar(content: Text('${request.name} kataloğa eklendi.')),
      );
    } catch (_) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Talep onaylanamadı.')),
      );
    }
  }

  Future<void> _reject(BuildContext context) async {
    final reasonCtrl = TextEditingController();
    final reason = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: FR.surface,
        title: Text('Talebi reddet', style: frDisplay(20, FontWeight.w700)),
        content: TextField(
          controller: reasonCtrl,
          maxLines: 3,
          decoration: const InputDecoration(hintText: 'Gerekçe (opsiyonel)'),
          style: frText(13, FontWeight.w600),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('İptal', style: frText(13, FontWeight.w800, color: FR.ink3)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, reasonCtrl.text.trim()),
            child: Text('Reddet', style: frText(13, FontWeight.w800, color: FR.bad)),
          ),
        ],
      ),
    );
    if (reason == null) return;
    try {
      await state.adminRejectRequest(req: request, reason: reason);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${request.name} reddedildi.')),
      );
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Talep reddedilemedi.')),
      );
    }
  }

  Future<void> _convert(BuildContext context) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ProductFormScreen.fromRequest(request: request),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: FR.surfaceHi,
                  borderRadius: FRRad.all(12),
                  border: Border.all(color: FR.hairline),
                ),
                alignment: Alignment.center,
                child: Text(request.emoji,
                    style: const TextStyle(fontSize: 20)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(request.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: frText(13, FontWeight.w800)),
                    Text(
                      '${request.brand} · ${request.unit} · ${request.category}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: frText(11, FontWeight.w600, color: FR.ink3),
                    ),
                    const SizedBox(height: 2),
                    Text('Talep eden: ${request.requestedByName}',
                        style: frText(10.5, FontWeight.w700, color: FR.ink3)),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  color: _statusColor.withOpacity(.14),
                  borderRadius: FRRad.all(999),
                  border: Border.all(color: _statusColor.withOpacity(.35)),
                ),
                child: Text(_statusLabel,
                    style: frText(10, FontWeight.w800, color: _statusColor)),
              ),
            ],
          ),
          if (request.note.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(request.note,
                style: frText(11.5, FontWeight.w600, color: FR.ink2)),
          ],
          if (!readOnly) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () => _approve(context),
                    borderRadius: FRRad.all(999),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 9),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: FR.good.withOpacity(.14),
                        borderRadius: FRRad.all(999),
                        border: Border.all(color: FR.good.withOpacity(.4)),
                      ),
                      child: Text('Onayla',
                          style: frText(12, FontWeight.w800, color: FR.good)),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: InkWell(
                    onTap: () => _convert(context),
                    borderRadius: FRRad.all(999),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 9),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: FR.gold.withOpacity(.14),
                        borderRadius: FRRad.all(999),
                        border: Border.all(color: FR.gold.withOpacity(.4)),
                      ),
                      child: Text('Düzenleyip ekle',
                          style: frText(12, FontWeight.w800, color: FR.gold)),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: InkWell(
                    onTap: () => _reject(context),
                    borderRadius: FRRad.all(999),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 9),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: FR.bad.withOpacity(.14),
                        borderRadius: FRRad.all(999),
                        border: Border.all(color: FR.bad.withOpacity(.4)),
                      ),
                      child: Text('Reddet',
                          style: frText(12, FontWeight.w800, color: FR.bad)),
                    ),
                  ),
                ),
              ],
            ),
          ],
          if (readOnly && request.rejectionReason != null) ...[
            const SizedBox(height: 6),
            Text('Gerekçe: ${request.rejectionReason}',
                style: frText(11, FontWeight.w600, color: FR.ink3)),
          ],
        ],
      ),
    );
  }
}

/// Admin-only full-screen form for creating or editing a product.
/// `existing` → edit; `fromRequest` → prefill from a pending request and
/// mark that request as approved after save.
class ProductFormScreen extends StatefulWidget {
  const ProductFormScreen({super.key, this.existing, this.sourceRequest});
  const ProductFormScreen.fromRequest({super.key, required ProductRequest request})
      : existing = null,
        sourceRequest = request;

  final Product? existing;
  final ProductRequest? sourceRequest;

  @override
  State<ProductFormScreen> createState() => _ProductFormScreenState();
}

class _ProductFormScreenState extends State<ProductFormScreen> {
  final _nameCtrl = TextEditingController();
  final _brandCtrl = TextEditingController();
  final _unitCtrl = TextEditingController();
  final _barcodeCtrl = TextEditingController();
  String _category = 'Tümü';
  String _emoji = '🛒';
  String? _currentImageUrl;
  String? _currentImagePath;
  Uint8List? _pendingImageBytes;
  bool _isActive = true;
  bool _saving = false;
  bool _deleting = false;

  static const _emojiPool = [
    '🛒', '🥛', '🍞', '🍳', '🧀', '🍎', '🥬', '🥕', '🍌', '🍊', '🍇',
    '🥦', '🍅', '🍝', '🍚', '🍲', '🫒', '☕', '🍵', '🥤', '🍫', '🍪',
    '🥜', '🧂', '🧼', '🧻', '🧴'
  ];

  @override
  void initState() {
    super.initState();
    final p = widget.existing;
    final req = widget.sourceRequest;
    if (p != null) {
      _nameCtrl.text = p.name;
      _brandCtrl.text = p.brand;
      _unitCtrl.text = p.unit;
      _barcodeCtrl.text = p.barcode ?? '';
      _category = p.category;
      _emoji = p.emoji;
      _currentImageUrl = p.imageUrl;
      _currentImagePath = p.imagePath;
      _isActive = p.isActive;
    } else if (req != null) {
      _nameCtrl.text = req.name;
      _brandCtrl.text = req.brand;
      _unitCtrl.text = req.unit;
      _barcodeCtrl.text = req.barcode;
      _category = req.category;
      _emoji = req.emoji.isEmpty ? '🛒' : req.emoji;
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _brandCtrl.dispose();
    _unitCtrl.dispose();
    _barcodeCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final x = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1200,
      imageQuality: 88,
    );
    if (x == null) return;
    final bytes = await x.readAsBytes();
    if (!mounted) return;
    setState(() => _pendingImageBytes = bytes);
  }

  Future<void> _save(AppState state) async {
    final name = _nameCtrl.text.trim();
    if (name.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ürün adı en az 2 karakter olmalı.')),
      );
      return;
    }
    setState(() => _saving = true);
    try {
      String? newImageUrl;
      String? newImagePath;

      if (widget.existing == null) {
        final productId = await state.adminCreateProduct(
          name: name,
          brand: _brandCtrl.text.trim(),
          category: _category,
          emoji: _emoji,
          unit: _unitCtrl.text.trim(),
          barcode: _barcodeCtrl.text.trim(),
          isActive: _isActive,
        );
        if (_pendingImageBytes != null) {
          final res = await FirebaseService.instance.uploadProductImage(
            productId: productId,
            bytes: _pendingImageBytes!,
          );
          newImageUrl = res.url;
          newImagePath = res.path;
          await state.adminUpdateProduct(
            productId: productId,
            imageUrl: newImageUrl,
            imagePath: newImagePath,
          );
        }
        if (widget.sourceRequest != null) {
          final r = widget.sourceRequest!;
          await FirebaseService.instance.productRequests.doc(r.id).update({
            'status': 'approved',
            'approvedProductId': productId,
            'decidedAt': FieldValue.serverTimestamp(),
            'decidedByUid': state.user?.uid ?? '',
          });
        }
      } else {
        final id = widget.existing!.id;
        final previousImagePath = _currentImagePath;
        if (_pendingImageBytes != null) {
          final res = await FirebaseService.instance.uploadProductImage(
            productId: id,
            bytes: _pendingImageBytes!,
          );
          newImageUrl = res.url;
          newImagePath = res.path;
        }
        await state.adminUpdateProduct(
          productId: id,
          name: name,
          brand: _brandCtrl.text.trim(),
          category: _category,
          emoji: _emoji,
          unit: _unitCtrl.text.trim(),
          barcode: _barcodeCtrl.text.trim(),
          isActive: _isActive,
          imageUrl: newImageUrl,
          imagePath: newImagePath,
        );
        if (newImagePath != null &&
            previousImagePath != null &&
            previousImagePath.isNotEmpty &&
            previousImagePath != newImagePath) {
          await FirebaseService.instance.deleteStorageFile(previousImagePath);
        }
      }
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(widget.existing == null
              ? 'Ürün oluşturuldu.'
              : 'Ürün güncellendi.'),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Kayıt başarısız: $e')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _delete(AppState state) async {
    final p = widget.existing;
    if (p == null) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: FR.surface,
        title: Text('Ürünü sil', style: frDisplay(20, FontWeight.w700)),
        content: Text(
          '${p.name} kalıcı olarak silinecek. Bu işlem geri alınamaz.',
          style: frText(13, FontWeight.w600, color: FR.ink2),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('İptal', style: frText(13, FontWeight.w800, color: FR.ink3)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Sil', style: frText(13, FontWeight.w800, color: FR.bad)),
          ),
        ],
      ),
    );
    if (ok != true) return;
    setState(() => _deleting = true);
    try {
      if (p.imagePath != null && p.imagePath!.isNotEmpty) {
        await FirebaseService.instance.deleteStorageFile(p.imagePath!);
      }
      await state.adminDeleteProduct(p.id);
      if (!mounted) return;
      Navigator.pop(context);
    } finally {
      if (mounted) setState(() => _deleting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = AppStateScope.of(context);
    final isEdit = widget.existing != null;

    return Scaffold(
      backgroundColor: FR.bg,
      body: SafeArea(
        bottom: false,
        child: Stack(
          children: [
            Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                  child: Row(
                    children: [
                      FRIconChip(
                        icon: Icons.arrow_back_rounded,
                        onTap: () => Navigator.pop(context),
                      ),
                      const Spacer(),
                      if (isEdit)
                        InkWell(
                          onTap: _deleting ? null : () => _delete(state),
                          borderRadius: FRRad.all(14),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 9),
                            decoration: BoxDecoration(
                              color: FR.bad.withOpacity(.1),
                              borderRadius: FRRad.all(14),
                              border: Border.all(color: FR.bad.withOpacity(.35)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.delete_outline_rounded,
                                    color: FR.bad, size: 16),
                                const SizedBox(width: 6),
                                Text('Sil',
                                    style: frText(11.5, FontWeight.w800, color: FR.bad)),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
                  child: FRPageHeader(
                    overline: isEdit ? 'DÜZENLE' : 'YENİ ÜRÜN',
                    title: isEdit ? 'Ürün' : 'Ürün',
                    italicTail: isEdit ? ' düzenle' : ' ekle',
                  ),
                ),
                Expanded(
                  child: ListView(
                    padding: EdgeInsets.fromLTRB(
                      20,
                      18,
                      20,
                      96 +
                          MediaQuery.of(context).viewPadding.bottom +
                          MediaQuery.of(context).viewInsets.bottom +
                          12,
                    ),
                    children: [
                      _imageBlock(),
                      const SizedBox(height: 16),
                      _label('Ürün adı'),
                      _input(_nameCtrl, 'Tam Yağlı Süt 1L'),
                      const SizedBox(height: 14),
                      _label('Marka'),
                      _input(_brandCtrl, 'Sütaş'),
                      const SizedBox(height: 14),
                      _label('Birim'),
                      _input(_unitCtrl, '1 L / 250 g / 30 adet'),
                      const SizedBox(height: 14),
                      _label('Barkod (opsiyonel)'),
                      _input(_barcodeCtrl, '8690…',
                          keyboard: TextInputType.number),
                      const SizedBox(height: 14),
                      _label('Kategori'),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          for (final c in state.categories)
                            InkWell(
                              onTap: () => setState(() => _category = c),
                              borderRadius: FRRad.all(999),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 8),
                                decoration: BoxDecoration(
                                  color: _category == c ? FR.gold : FR.surface,
                                  borderRadius: FRRad.all(999),
                                  border: Border.all(
                                    color:
                                        _category == c ? FR.gold : FR.hairline,
                                  ),
                                ),
                                child: Text(
                                  c,
                                  style: frText(12, FontWeight.w800,
                                      color:
                                          _category == c ? FR.bg : FR.ink),
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      _label('İkon'),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: [
                          for (final e in _emojiPool)
                            InkWell(
                              onTap: () => setState(() => _emoji = e),
                              borderRadius: FRRad.all(10),
                              child: Container(
                                width: 40,
                                height: 40,
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  color: _emoji == e
                                      ? FR.gold.withOpacity(.18)
                                      : FR.surface,
                                  borderRadius: FRRad.all(10),
                                  border: Border.all(
                                    color: _emoji == e ? FR.gold : FR.hairline,
                                  ),
                                ),
                                child: Text(e,
                                    style: const TextStyle(fontSize: 20)),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: frSurface(radius: FRRad.l),
                        child: Row(
                          children: [
                            Container(
                              width: 38,
                              height: 38,
                              decoration: BoxDecoration(
                                color: FR.surfaceHi,
                                borderRadius: FRRad.all(12),
                                border: Border.all(color: FR.hairline),
                              ),
                              child: Icon(Icons.visibility_outlined,
                                  color: FR.gold, size: 18),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Aktif',
                                      style: frText(13.5, FontWeight.w800)),
                                  Text(
                                    _isActive
                                        ? 'Kullanıcılar bu ürünü görebilir'
                                        : 'Gizli — sadece admin panelinde',
                                    style: frText(11.5, FontWeight.w600,
                                        color: FR.ink3),
                                  ),
                                ],
                              ),
                            ),
                            Switch(
                              value: _isActive,
                              activeColor: FR.bg,
                              activeTrackColor: FR.gold,
                              inactiveThumbColor: FR.ink2,
                              inactiveTrackColor: FR.surfaceHi,
                              onChanged: (v) =>
                                  setState(() => _isActive = v),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                padding: EdgeInsets.fromLTRB(
                  20,
                  12,
                  20,
                  12 + MediaQuery.of(context).viewPadding.bottom,
                ),
                decoration: BoxDecoration(
                  color: FR.bgElev,
                  border: Border(top: BorderSide(color: FR.hairline)),
                ),
                child: FRCta(
                  label: _saving
                      ? 'Kaydediliyor…'
                      : (isEdit ? 'Değişiklikleri kaydet' : 'Ürünü oluştur'),
                  icon: Icons.check_rounded,
                  onTap: _saving ? null : () => _save(state),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _imageBlock() {
    return InkWell(
      onTap: _pickImage,
      borderRadius: FRRad.all(FRRad.xl),
      child: Container(
        height: 180,
        decoration: BoxDecoration(
          color: FR.surface,
          borderRadius: FRRad.all(FRRad.xl),
          border: Border.all(color: FR.hairline),
        ),
        child: Stack(
          children: [
            Positioned.fill(
              child: _pendingImageBytes != null
                  ? ClipRRect(
                      borderRadius: FRRad.all(FRRad.xl),
                      child: Image.memory(
                        _pendingImageBytes!,
                        fit: BoxFit.cover,
                      ),
                    )
                  : (_currentImageUrl != null
                      ? ClipRRect(
                          borderRadius: FRRad.all(FRRad.xl),
                          child: Image.network(
                            _currentImageUrl!,
                            fit: BoxFit.cover,
                            cacheWidth: 1400,
                            filterQuality: FilterQuality.medium,
                          ),
                        )
                      : Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.photo_outlined,
                                  color: FR.gold, size: 36),
                              const SizedBox(height: 6),
                              Text(
                                'Ürün görseli ekle',
                                style: frText(12.5, FontWeight.w800),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Galeriden seç · JPG/PNG · 1200px',
                                style: frText(11, FontWeight.w600,
                                    color: FR.ink3),
                              ),
                            ],
                          ),
                        )),
            ),
            Positioned(
              right: 10,
              bottom: 10,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: FR.surface.withOpacity(FR.isDark ? .78 : .92),
                  borderRadius: FRRad.all(999),
                  border: Border.all(color: FR.hairline),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.upload_outlined,
                        color: FR.gold, size: 14),
                    const SizedBox(width: 6),
                    Text(
                      _pendingImageBytes != null
                          ? 'Görsel değiştirildi'
                          : (_currentImageUrl != null
                              ? 'Değiştir'
                              : 'Görsel yükle'),
                      style: frText(11, FontWeight.w800, color: FR.gold),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _label(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(
          children: [
            Container(width: 3, height: 14, color: FR.gold),
            const SizedBox(width: 8),
            Text(text,
                style: frText(12, FontWeight.w800, color: FR.ink, letter: .4)),
          ],
        ),
      );

  Widget _input(TextEditingController c, String hint,
      {TextInputType? keyboard}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
      decoration: frSurface(radius: FRRad.m),
      child: TextField(
        controller: c,
        keyboardType: keyboard,
        style: frText(14, FontWeight.w700),
        cursorColor: FR.gold,
        decoration: InputDecoration(
          border: InputBorder.none,
          hintText: hint,
          hintStyle: frText(13, FontWeight.w600, color: FR.ink3),
        ),
      ),
    );
  }
}

class _PricesTab extends StatelessWidget {
  const _PricesTab({required this.state});
  final AppState state;

  @override
  Widget build(BuildContext context) {
    final recent = state.adminRecentEntries.take(20).toList();
    if (recent.isEmpty) return _empty('Fiyat akışı boş.');
    return _rowList([
      for (final r in recent) _EntryRow(product: r.$1, entry: r.$2),
    ]);
  }
}

class _VerificationTab extends StatelessWidget {
  const _VerificationTab({required this.state});
  final AppState state;

  @override
  Widget build(BuildContext context) {
    final pending = state.adminPendingEntries.take(20).toList();
    final disputed = state.adminDisputedEntries.take(20).toList();
    if (pending.isEmpty && disputed.isEmpty) {
      return _empty('Tüm fiyatlar doğrulanmış.');
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (disputed.isNotEmpty) ...[
          const FRSectionHead(eyebrow: 'DİKKAT', title: 'İhtilaflı fiyatlar'),
          const SizedBox(height: 10),
          _rowList([
            for (final r in disputed) _EntryRow(product: r.$1, entry: r.$2),
          ]),
          const SizedBox(height: 18),
        ],
        if (pending.isNotEmpty) ...[
          const FRSectionHead(eyebrow: 'BEKLEYEN', title: 'Topluluk oyuna açık'),
          const SizedBox(height: 10),
          _rowList([
            for (final r in pending) _EntryRow(product: r.$1, entry: r.$2),
          ]),
        ],
      ],
    );
  }
}

class _ModerationTab extends StatelessWidget {
  const _ModerationTab({required this.state});
  final AppState state;

  @override
  Widget build(BuildContext context) {
    final rejected = state.adminRejectedEntries.take(20).toList();
    if (rejected.isEmpty) return _empty('Reddedilmiş fiyat yok.');
    return _rowList([
      for (final r in rejected) _EntryRow(product: r.$1, entry: r.$2),
    ]);
  }
}

class _SettingsTab extends StatelessWidget {
  const _SettingsTab({required this.state});
  final AppState state;

  @override
  Widget build(BuildContext context) {
    return _rowList([
      const _GenericRow(
        title: 'Minimum oy sayısı',
        subtitle:
            '${VerificationRules.minVotesForStatus} oy sonrası durum değişir',
        icon: Icons.verified_rounded,
        withActions: false,
      ),
      const _GenericRow(
        title: 'Doğrulama eşiği',
        subtitle:
            'Güven ağırlıklı skor ≥ ${VerificationRules.verifyScore} → doğrulandı',
        icon: Icons.tune_rounded,
        withActions: false,
      ),
      const _GenericRow(
        title: 'Red eşiği',
        subtitle:
            'Güven ağırlıklı skor ≤ ${VerificationRules.rejectScore} → reddedildi',
        icon: Icons.block_rounded,
        withActions: false,
      ),
      _GenericRow(
        title: 'Senin trust ağırlığın',
        subtitle:
            '%${state.trustScorePercent} güven · oyun ${state.voteWeight.toStringAsFixed(2)}x ağırlıkta',
        icon: Icons.shield_moon_outlined,
        withActions: false,
      ),
      _GenericRow(
        title: 'Market yönetimi',
        subtitle: 'Ekle · düzenle · sil',
        icon: Icons.storefront_outlined,
        withActions: true,
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const AdminStoreCrudScreen()),
        ),
      ),
      _GenericRow(
        title: 'Kategori yönetimi',
        subtitle: 'Ekle · düzenle · sil',
        icon: Icons.category_outlined,
        withActions: true,
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const AdminCategoryCrudScreen()),
        ),
      ),
      _GenericRow(
        title: 'Kullanıcı düzenleme',
        subtitle: 'Ad · kullanıcı adı · admin rolü',
        icon: Icons.people_outline_rounded,
        withActions: true,
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const AdminUserEditScreen()),
        ),
      ),
      _GenericRow(
        title: 'Fiyat raporları',
        subtitle: 'Gelen raporları incele',
        icon: Icons.flag_outlined,
        withActions: true,
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const AdminPriceReportsScreen()),
        ),
      ),
    ]);
  }
}

class AdminStoreCrudScreen extends StatelessWidget {
  const AdminStoreCrudScreen({super.key});

  static String _normalizeName(String value) =>
      value.trim().replaceAll(RegExp(r'\s+'), ' ').toLowerCase();

  Future<QueryDocumentSnapshot<Map<String, dynamic>>?> _findByNormalizedName(
    String normalized, {
    String? excludingDocId,
  }) async {
    final docs = await FirebaseService.instance.stores.get();
    for (final doc in docs.docs) {
      if (excludingDocId != null && doc.id == excludingDocId) continue;
      final data = doc.data();
      final docNormalized = ((data['nameNormalized'] ?? '') as String).trim();
      final docNameNormalized = docNormalized.isNotEmpty
          ? docNormalized.toLowerCase()
          : _normalizeName((data['name'] ?? '').toString());
      if (docNameNormalized == normalized) {
        return doc;
      }
    }
    return null;
  }

  Future<void> _createStore(String rawName) async {
    final name = rawName.trim().replaceAll(RegExp(r'\s+'), ' ');
    final normalized = _normalizeName(name);
    final coll = FirebaseService.instance.stores;
    final dupDoc = await _findByNormalizedName(normalized);
    if (dupDoc != null) {
      await dupDoc.reference.update({
        'name': name,
        'nameNormalized': normalized,
        'isActive': true,
      });
      return;
    }
    await coll.add({
      'name': name,
      'nameNormalized': normalized,
      'order': DateTime.now().millisecondsSinceEpoch,
      'isActive': true,
    });
  }

  Future<void> _renameStore(
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
    String rawName,
  ) async {
    final name = rawName.trim().replaceAll(RegExp(r'\s+'), ' ');
    final normalized = _normalizeName(name);
    final dupDoc = await _findByNormalizedName(
      normalized,
      excludingDocId: doc.id,
    );
    if (dupDoc != null) {
      throw Exception('Bu market adı zaten kayıtlı.');
    }
    await doc.reference.update({
      'name': name,
      'nameNormalized': normalized,
    });
  }

  @override
  Widget build(BuildContext context) {
    final stores = FirebaseService.instance.stores.orderBy('order').snapshots();
    return _AdminCrudScaffold(
      title: 'Market yönetimi',
      onAdd: () => _showTextEditSheet(
        context,
        title: 'Market ekle',
        onSave: _createStore,
      ),
      child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: stores,
        builder: (_, snap) {
          if (snap.hasError) return _empty('Market verisi yüklenemedi.');
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final docs = snap.data?.docs ?? const [];
          if (docs.isEmpty) return _empty('Market kaydı yok.');
          return _rowList([
            for (final d in docs)
              _CrudRow(
                title: (d.data()['name'] ?? '').toString(),
                subtitle: (d.data()['isActive'] ?? true) ? 'Aktif' : 'Pasif',
                onEdit: () => _showTextEditSheet(
                  context,
                  title: 'Market düzenle',
                  initial: (d.data()['name'] ?? '').toString(),
                  onSave: (name) => _renameStore(d, name),
                ),
                onDelete: () => d.reference.delete(),
                onToggleActive: () => d.reference.update({
                  'isActive': !((d.data()['isActive'] as bool?) ?? true),
                }),
              ),
          ]);
        },
      ),
    );
  }
}

class AdminCategoryCrudScreen extends StatelessWidget {
  const AdminCategoryCrudScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final categories =
        FirebaseService.instance.categories.orderBy('order').snapshots();
    return _AdminCrudScaffold(
      title: 'Kategori yönetimi',
      onAdd: () => _showTextEditSheet(
        context,
        title: 'Kategori ekle',
        onSave: (name) => FirebaseService.instance.categories.add({
          'name': name,
          'order': DateTime.now().millisecondsSinceEpoch,
          'isActive': true,
        }),
      ),
      child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: categories,
        builder: (_, snap) {
          if (snap.hasError) return _empty('Kategori verisi yüklenemedi.');
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final docs = snap.data?.docs ?? const [];
          if (docs.isEmpty) return _empty('Kategori kaydı yok.');
          return _rowList([
            for (final d in docs)
              _CrudRow(
                title: (d.data()['name'] ?? '').toString(),
                subtitle: (d.data()['isActive'] ?? true) ? 'Aktif' : 'Pasif',
                onEdit: () => _showTextEditSheet(
                  context,
                  title: 'Kategori düzenle',
                  initial: (d.data()['name'] ?? '').toString(),
                  onSave: (name) => d.reference.update({'name': name}),
                ),
                onDelete: () => d.reference.delete(),
                onToggleActive: () => d.reference.update({
                  'isActive': !((d.data()['isActive'] as bool?) ?? true),
                }),
              ),
          ]);
        },
      ),
    );
  }
}

class AdminUserEditScreen extends StatelessWidget {
  const AdminUserEditScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final users = FirebaseService.instance.users.limit(300).snapshots();
    return _AdminCrudScaffold(
      title: 'Kullanıcı düzenleme',
      child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: users,
        builder: (_, snap) {
          if (snap.hasError) return _empty('Kullanıcı verisi yüklenemedi.');
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final docs = snap.data?.docs ?? const [];
          if (docs.isEmpty) return _empty('Kullanıcı bulunamadı.');
          return _rowList([
            for (final d in docs)
              _UserEditRow(
                uid: d.id,
                data: d.data(),
              ),
          ]);
        },
      ),
    );
  }
}

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
    return _AdminCrudScaffold(
      title: 'Fiyat raporları',
      child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: reports,
        builder: (_, snap) {
          if (snap.hasError) return _empty('Raporlar yüklenemedi.');
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final docs = snap.data?.docs ?? const [];
          if (docs.isEmpty) return _empty('Henüz rapor yok.');
          return _rowList([
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
    final by = (m['createdByUid'] ?? '').toString();
    final status = (m['status'] ?? 'active').toString();
    final reason = (m['reason'] ?? '').toString();
    return _CrudRow(
      title: 'Ürün: $productId · $price ₺',
      subtitle: 'Raporlayan: $by · $status${reason.isEmpty ? '' : ' · $reason'}',
      onEdit: _busy ? () {} : () => _resolve(removeEntry: true),
      onDelete: _busy ? () {} : () => _resolve(removeEntry: false),
      editLabel: _busy ? 'İşleniyor…' : 'Girdiyi kaldır',
      deleteLabel: _busy ? 'Bekle…' : 'İncelendi',
    );
  }
}

class _AdminCrudScaffold extends StatelessWidget {
  const _AdminCrudScaffold({
    required this.title,
    required this.child,
    this.onAdd,
  });
  final String title;
  final Widget child;
  final VoidCallback? onAdd;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: FR.bg,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
              child: Row(
                children: [
                  FRIconChip(
                    icon: Icons.arrow_back_rounded,
                    onTap: () => Navigator.pop(context),
                  ),
                  const Spacer(),
                  if (onAdd != null)
                    FRIconChip(icon: Icons.add_rounded, onTap: onAdd),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
              child: FRPageHeader(overline: 'ADMIN', title: title),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                children: [child],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CrudRow extends StatelessWidget {
  const _CrudRow({
    required this.title,
    required this.subtitle,
    required this.onEdit,
    required this.onDelete,
    this.onToggleActive,
    this.editLabel = 'Düzenle',
    this.deleteLabel = 'Sil',
  });
  final String title;
  final String subtitle;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback? onToggleActive;
  final String editLabel;
  final String deleteLabel;

  @override
  Widget build(BuildContext context) {
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
          Text(title, style: frText(13, FontWeight.w800)),
          const SizedBox(height: 2),
          Text(subtitle, style: frText(11.5, FontWeight.w600, color: FR.ink3)),
          const SizedBox(height: 10),
          Row(
            children: [
              if (onToggleActive != null) ...[
                Expanded(
                  child: FRCta(
                    label: 'Aktif/Pasif',
                    filled: false,
                    onTap: onToggleActive,
                  ),
                ),
                const SizedBox(width: 8),
              ],
              Expanded(
                child: FRCta(
                  label: editLabel,
                  filled: false,
                  onTap: onEdit,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: FRCta(
                  label: deleteLabel,
                  icon: Icons.delete_outline_rounded,
                  onTap: onDelete,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _UserEditRow extends StatefulWidget {
  const _UserEditRow({required this.uid, required this.data});
  final String uid;
  final Map<String, dynamic> data;

  @override
  State<_UserEditRow> createState() => _UserEditRowState();
}

class _UserEditRowState extends State<_UserEditRow> {
  late final TextEditingController _name =
      TextEditingController(text: (widget.data['displayName'] ?? '').toString());
  late final TextEditingController _username =
      TextEditingController(text: (widget.data['username'] ?? '').toString());
  bool _saving = false;
  bool _roleSaving = false;

  @override
  void dispose() {
    _name.dispose();
    _username.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      await FirebaseService.instance.users.doc(widget.uid).update({
        'displayName': _name.text.trim(),
        'username': _username.text.trim(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Kullanıcı bilgileri güncellendi.')),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Kullanıcı bilgileri kaydedilemedi.')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _toggleAdmin(bool v) async {
    if (_roleSaving) return;
    setState(() => _roleSaving = true);
    try {
      await FirebaseService.instance.users.doc(widget.uid).update({
        'isAdmin': v,
        'role': v ? 'admin' : 'user',
        'updatedAt': FieldValue.serverTimestamp(),
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(v ? 'Admin yetkisi verildi.' : 'Admin yetkisi kaldırıldı.')),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Yetki güncellenemedi.')),
      );
    } finally {
      if (mounted) setState(() => _roleSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isAdmin = (widget.data['isAdmin'] as bool?) == true ||
        (widget.data['role'] as String?) == 'admin';
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: FR.surface,
        borderRadius: FRRad.all(FRRad.l),
        border: Border.all(color: FR.hairline),
      ),
      child: Column(
        children: [
          TextField(
            controller: _name,
            decoration: const InputDecoration(hintText: 'Ad Soyad'),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _username,
            decoration: const InputDecoration(hintText: 'Kullanıcı adı'),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Text('UID: ${widget.uid.substring(0, widget.uid.length > 8 ? 8 : widget.uid.length)}',
                  style: frText(10.5, FontWeight.w700, color: FR.ink3)),
              const Spacer(),
              Switch(
                value: isAdmin,
                onChanged: _roleSaving ? null : _toggleAdmin,
                activeColor: FR.bg,
                activeTrackColor: FR.gold,
                inactiveThumbColor: FR.ink2,
                inactiveTrackColor: FR.surfaceHi,
              ),
              const SizedBox(width: 8),
              FRCta(
                label: _saving ? 'Kaydediliyor…' : 'Kaydet',
                filled: false,
                onTap: _saving ? null : _save,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

Future<void> _showTextEditSheet(
  BuildContext context, {
  required String title,
  String initial = '',
  required Future<void> Function(String value) onSave,
}) async {
  final ctrl = TextEditingController(text: initial);
  final ok = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: FR.surface,
      title: Text(title, style: frDisplay(20, FontWeight.w700)),
      content: TextField(
        controller: ctrl,
        decoration: InputDecoration(
          hintText: 'Ad',
          hintStyle: frText(12, FontWeight.w600, color: FR.ink3),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: Text('İptal', style: frText(12.5, FontWeight.w800, color: FR.ink3)),
        ),
        TextButton(
          onPressed: () => Navigator.pop(ctx, true),
          child: Text('Kaydet', style: frText(12.5, FontWeight.w800, color: FR.gold)),
        ),
      ],
    ),
  );
  if (ok == true && ctrl.text.trim().isNotEmpty) {
    try {
      await onSave(ctrl.text.trim());
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$e')),
      );
    }
  }
  ctrl.dispose();
}

Widget _empty(String label) {
  return Container(
    padding: const EdgeInsets.all(20),
    decoration: frSurface(radius: FRRad.l),
    alignment: Alignment.center,
    child: Text(label, style: frText(12.5, FontWeight.w600, color: FR.ink3)),
  );
}

Widget _rowList(List<Widget> rows) {
  return Column(
    children: [
      for (var i = 0; i < rows.length; i++) ...[
        rows[i],
        if (i < rows.length - 1) const SizedBox(height: 10),
      ],
    ],
  );
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.value,
    required this.label,
    required this.delta,
    required this.deltaGood,
  });
  final String value;
  final String label;
  final String delta;
  final bool deltaGood;

  @override
  Widget build(BuildContext context) {
    final deltaColor = deltaGood ? FR.good : FR.warn;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [FR.surfaceHi, FR.surfaceLo],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: FRRad.all(FRRad.l),
        border: Border.all(color: FR.goldDeep.withOpacity(.28)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: frOverline(color: FR.ink3, size: 9.5)),
          const SizedBox(height: 10),
          Text(value, style: frDisplay(28, FontWeight.w700)),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: deltaColor.withOpacity(.14),
              borderRadius: FRRad.all(999),
              border: Border.all(color: deltaColor.withOpacity(.35)),
            ),
            child: Text(delta,
                style: frText(10.5, FontWeight.w800, color: deltaColor)),
          ),
        ],
      ),
    );
  }
}

class _EntryRow extends StatelessWidget {
  const _EntryRow({required this.product, required this.entry});
  final Product product;
  final PriceEntry entry;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: FR.surface,
        borderRadius: FRRad.all(FRRad.l),
        border: Border.all(color: FR.hairline),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: FR.surfaceHi,
              borderRadius: FRRad.all(12),
              border: Border.all(color: FR.hairline),
            ),
            alignment: Alignment.center,
            child: Text(product.emoji, style: const TextStyle(fontSize: 19)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${product.name} · ${entry.store}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: frText(13, FontWeight.w800)),
                const SizedBox(height: 2),
                Text(
                  '${entry.reportedBy} · ${entry.price.toStringAsFixed(2)} ₺ · '
                  '↑${entry.upvotes} ↓${entry.downvotes}',
                  style: frText(11, FontWeight.w600, color: FR.ink3),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          FRVerifyBadge.status(
            status: statusToString(entry.status),
            trustPercent: entry.trustPercent,
            dense: true,
          ),
        ],
      ),
    );
  }
}

class _GenericRow extends StatelessWidget {
  const _GenericRow({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.withActions,
    this.onTap,
  });
  final String title;
  final String subtitle;
  final IconData icon;
  final bool withActions;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: FRRad.all(FRRad.l),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: FR.surface,
          borderRadius: FRRad.all(FRRad.l),
          border: Border.all(color: FR.hairline),
        ),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: FR.surfaceHi,
                borderRadius: FRRad.all(12),
                border: Border.all(color: FR.hairline),
              ),
              child: Icon(icon, size: 17, color: FR.gold),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: frText(13, FontWeight.w800),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 2),
                  Text(subtitle,
                      style: frText(11, FontWeight.w600, color: FR.ink3),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
            if (withActions)
              Icon(Icons.chevron_right_rounded, color: FR.ink3),
          ],
        ),
      ),
    );
  }
}
