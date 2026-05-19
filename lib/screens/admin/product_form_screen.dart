import 'dart:async';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

import '../../features/admin/illustration_picker/illustration_manifest_service.dart';
import '../../features/admin/illustration_picker/illustration_picker_screen.dart';
import '../../features/admin/models/illustration_asset.dart';
import '../../models/product.dart';
import '../../services/firebase_service.dart';
import '../../services/openfoodfacts_service.dart';
import '../../state/app_state.dart';
import '../../ui/components.dart';
import '../../ui/tokens.dart';

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
  // Legacy emoji column kept for backwards compatibility with older
  // product docs; admin no longer picks one — barcode/illustration
  // fallback handles the visual.
  String _emoji = '🛒';
  String? _currentImageUrl;
  String? _currentImagePath;
  Uint8List? _pendingImageBytes;
  // OpenFoodFacts ile getirilen, henüz kaydedilmemiş URL. Save akışı
  // bunu Storage'a kopyalayarak kalıcı `product_images/...` URL'i üretir.
  String? _pendingRemoteImageUrl;
  bool _isActive = true;
  bool _saving = false;
  bool _deleting = false;
  bool _lookingUpBarcode = false;
  String? _barcodeLookupError;

  /// Manifest id of the brand-agnostic illustration assigned to this
  /// product. `null` means the admin has not picked one (or cleared it).
  String? _assignedIllustrationId;
  IllustrationAsset? _assignedIllustration;

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
      _assignedIllustrationId = p.assignedIllustrationId;
      if (_assignedIllustrationId != null) {
        IllustrationManifestService.findById(_assignedIllustrationId!)
            .then((asset) {
          if (!mounted || asset == null) return;
          setState(() => _assignedIllustration = asset);
        });
      }
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
    setState(() {
      _pendingImageBytes = bytes;
      // Local seçim, OpenFoodFacts ön izlemesini ezsin.
      _pendingRemoteImageUrl = null;
    });
  }

  Future<void> _lookupBarcode() async {
    final code = _barcodeCtrl.text.trim();
    if (code.isEmpty) {
      setState(() => _barcodeLookupError =
          'Önce barkod numarasını gir (EAN-8/13).');
      return;
    }
    setState(() {
      _lookingUpBarcode = true;
      _barcodeLookupError = null;
    });
    try {
      final result =
          await OpenFoodFactsService.instance.lookup(code);
      if (!mounted) return;
      if (result == null) {
        setState(() {
          _barcodeLookupError =
              'OpenFoodFacts bu barkodda bir görsel bulamadı.';
        });
        return;
      }
      // Görsel byte'larını çekip lokal preview'a koy. Save akışı bu
      // bytes'ı Storage'a yükleyip imageUrl alanını yazacak — böylece
      // production'da OpenFoodFacts CDN'ine bağımlı kalmıyoruz.
      Uint8List? bytes;
      try {
        final resp = await http
            .get(Uri.parse(result.imageUrl))
            .timeout(const Duration(seconds: 10));
        if (resp.statusCode == 200 && resp.bodyBytes.isNotEmpty) {
          bytes = resp.bodyBytes;
        }
      } catch (_) {/* sessizce yedek URL'e düş */}

      if (!mounted) return;
      setState(() {
        if (bytes != null) {
          _pendingImageBytes = bytes;
          _pendingRemoteImageUrl = null;
        } else {
          // Bytes çekilemediyse URL'i tut, Save'de tekrar denenecek.
          _pendingImageBytes = null;
          _pendingRemoteImageUrl = result.imageUrl;
        }
        // İsim/marka/birim alanı boşsa öneri olarak doldur — admin
        // istemezse üzerine yazar.
        if (_nameCtrl.text.trim().isEmpty &&
            (result.productName ?? '').isNotEmpty) {
          _nameCtrl.text = result.productName!;
        }
        if (_brandCtrl.text.trim().isEmpty &&
            (result.brand ?? '').isNotEmpty) {
          _brandCtrl.text = result.brand!.split(',').first.trim();
        }
        if (_unitCtrl.text.trim().isEmpty &&
            (result.quantity ?? '').isNotEmpty) {
          _unitCtrl.text = result.quantity!;
        }
      });
    } finally {
      if (mounted) setState(() => _lookingUpBarcode = false);
    }
  }

  Future<Uint8List?> _bytesForPendingImage() async {
    if (_pendingImageBytes != null) return _pendingImageBytes;
    final remote = _pendingRemoteImageUrl;
    if (remote == null || remote.isEmpty) return null;
    try {
      final resp = await http
          .get(Uri.parse(remote))
          .timeout(const Duration(seconds: 12));
      if (resp.statusCode == 200 && resp.bodyBytes.isNotEmpty) {
        return resp.bodyBytes;
      }
    } catch (_) {}
    return null;
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
      final pendingBytes = await _bytesForPendingImage();

      if (widget.existing == null) {
        final productId = await state.adminCreateProduct(
          name: name,
          brand: _brandCtrl.text.trim(),
          category: _category,
          emoji: _emoji,
          unit: _unitCtrl.text.trim(),
          barcode: _barcodeCtrl.text.trim(),
          isActive: _isActive,
          assignedIllustrationId: _assignedIllustrationId,
        );
        if (pendingBytes != null) {
          final res = await FirebaseService.instance.uploadProductImage(
            productId: productId,
            bytes: pendingBytes,
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
        if (pendingBytes != null) {
          final res = await FirebaseService.instance.uploadProductImage(
            productId: id,
            bytes: pendingBytes,
          );
          newImageUrl = res.url;
          newImagePath = res.path;
        }
        final previousIllustrationId = widget.existing!.assignedIllustrationId;
        final illustrationChanged =
            previousIllustrationId != _assignedIllustrationId;
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
          assignedIllustrationId: _assignedIllustrationId,
          clearAssignedIllustration: illustrationChanged &&
              (_assignedIllustrationId == null || _assignedIllustrationId!.isEmpty),
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
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 0), // LEGACY_EXCEPTION: reason=token_migration owner=codex remove_by=2026-06-30
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
                            padding: const EdgeInsets.symmetric( // LEGACY_EXCEPTION: reason=token_migration owner=codex remove_by=2026-06-30
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
                  padding: const EdgeInsets.fromLTRB(20, 14, 20, 0), // LEGACY_EXCEPTION: reason=token_migration owner=codex remove_by=2026-06-30
                  child: FRPageHeader(
                    overline: isEdit ? 'DÜZENLE' : 'YENİ ÜRÜN',
                    title: isEdit ? 'Ürün' : 'Ürün',
                    italicTail: isEdit ? ' düzenle' : ' ekle',
                  ),
                ),
                Expanded(
                  child: ListView(
                    padding: EdgeInsets.fromLTRB( // LEGACY_EXCEPTION: reason=token_migration owner=codex remove_by=2026-06-30
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
                      _label('Kategori görseli'),
                      _illustrationBlock(),
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
                      _barcodeBlock(),
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
                                padding: const EdgeInsets.symmetric( // LEGACY_EXCEPTION: reason=token_migration owner=codex remove_by=2026-06-30
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
                      Container(
                        padding: const EdgeInsets.all(14), // LEGACY_EXCEPTION: reason=token_migration owner=codex remove_by=2026-06-30
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
                padding: EdgeInsets.fromLTRB( // LEGACY_EXCEPTION: reason=token_migration owner=codex remove_by=2026-06-30
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

  Future<void> _openIllustrationPicker() async {
    final selected = await Navigator.of(context).push<IllustrationAsset?>(
      MaterialPageRoute(
        builder: (_) => IllustrationPickerScreen(
          currentIllustrationId: _assignedIllustrationId,
        ),
      ),
    );
    if (!mounted || selected == null) return;
    setState(() {
      _assignedIllustrationId = selected.id;
      _assignedIllustration = selected;
    });
  }

  void _clearIllustration() {
    setState(() {
      _assignedIllustrationId = null;
      _assignedIllustration = null;
    });
  }

  Widget _illustrationBlock() {
    final asset = _assignedIllustration;
    final hasId = _assignedIllustrationId != null;
    return InkWell(
      onTap: _openIllustrationPicker,
      borderRadius: FRRad.all(FRRad.l),
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
        decoration: frSurface(radius: FRRad.l),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 76,
              decoration: BoxDecoration(
                color: FR.surfaceHi,
                borderRadius: FRRad.all(12),
                border: Border.all(color: FR.hairline),
              ),
              child: asset != null
                  ? Padding(
                      padding: const EdgeInsets.all(6),
                      child: SvgPicture.asset(
                        asset.assetPath,
                        fit: BoxFit.contain,
                        semanticsLabel: asset.label,
                      ),
                    )
                  : Icon(Icons.photo_size_select_actual_outlined,
                      color: FR.gold, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    asset != null
                        ? asset.label
                        : (hasId
                            ? 'Görsel yükleniyor…'
                            : 'Kategori görseli ata'),
                    style: frText(13.5, FontWeight.w800),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    asset != null
                        ? '${asset.categoryLabel} · marka-bağımsız kütüphane'
                        : 'Marka-bağımsız kategori illüstrasyonu seç',
                    style: frText(11.5, FontWeight.w600, color: FR.ink3),
                  ),
                ],
              ),
            ),
            if (asset != null)
              InkWell(
                onTap: _clearIllustration,
                borderRadius: FRRad.all(999),
                child: Padding(
                  padding: const EdgeInsets.all(6),
                  child: Icon(Icons.close_rounded, color: FR.ink3, size: 18),
                ),
              ),
            Icon(Icons.chevron_right_rounded, color: FR.gold, size: 22),
          ],
        ),
      ),
    );
  }

  Widget _barcodeBlock() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.fromLTRB(14, 2, 6, 2),
          decoration: frSurface(radius: FRRad.m),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _barcodeCtrl,
                  keyboardType: TextInputType.number,
                  style: frText(14, FontWeight.w700),
                  cursorColor: FR.gold,
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    hintText: '8690…',
                    hintStyle:
                        frText(13, FontWeight.w600, color: FR.ink3),
                  ),
                  onChanged: (_) {
                    if (_barcodeLookupError != null) {
                      setState(() => _barcodeLookupError = null);
                    }
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: InkWell(
                  onTap: _lookingUpBarcode ? null : _lookupBarcode,
                  borderRadius: FRRad.all(10),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: FR.gold.withOpacity(.16),
                      borderRadius: FRRad.all(10),
                      border: Border.all(color: FR.gold.withOpacity(.45)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (_lookingUpBarcode)
                          SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: FR.gold,
                            ),
                          )
                        else
                          Icon(Icons.download_rounded,
                              color: FR.gold, size: 16),
                        const SizedBox(width: 6),
                        Text(
                          _lookingUpBarcode
                              ? 'Aranıyor…'
                              : 'Görseli getir',
                          style: frText(11.5, FontWeight.w800,
                              color: FR.gold),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        if (_barcodeLookupError != null) ...[
          const SizedBox(height: 8),
          Text(
            _barcodeLookupError!,
            style: frText(11.5, FontWeight.w700, color: FR.bad),
          ),
        ] else ...[
          const SizedBox(height: 8),
          Text(
            'Barkod gir ve OpenFoodFacts\'tan ürün görselini otomatik çek.',
            style: frText(11.5, FontWeight.w600, color: FR.ink3),
          ),
        ],
      ],
    );
  }

  Widget _imageBlock() {
    Widget? preview;
    if (_pendingImageBytes != null) {
      preview = Image.memory(_pendingImageBytes!, fit: BoxFit.cover);
    } else if (_pendingRemoteImageUrl != null) {
      preview = Image.network(
        _pendingRemoteImageUrl!,
        fit: BoxFit.cover,
        cacheWidth: 1400,
        filterQuality: FilterQuality.medium,
      );
    } else if (_currentImageUrl != null) {
      preview = Image.network(
        _currentImageUrl!,
        fit: BoxFit.cover,
        cacheWidth: 1400,
        filterQuality: FilterQuality.medium,
      );
    }
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
              child: preview != null
                  ? ClipRRect(
                      borderRadius: FRRad.all(FRRad.xl),
                      child: preview,
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
                    ),
            ),
            Positioned(
              right: 10,
              bottom: 10,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6), // LEGACY_EXCEPTION: reason=token_migration owner=codex remove_by=2026-06-30
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
                          : (_pendingRemoteImageUrl != null
                              ? 'OpenFoodFacts ön izleme'
                              : (_currentImageUrl != null
                                  ? 'Değiştir'
                                  : 'Görsel yükle')),
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
        padding: const EdgeInsets.only(bottom: 8), // LEGACY_EXCEPTION: reason=token_migration owner=codex remove_by=2026-06-30
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
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2), // LEGACY_EXCEPTION: reason=token_migration owner=codex remove_by=2026-06-30
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
