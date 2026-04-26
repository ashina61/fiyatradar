import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../services/firebase_service.dart';
import '../state/app_state.dart';
import '../ui/components.dart';
import '../ui/tokens.dart';

/// User-facing product-request flow. The user fills in product meta; the
/// document lands in `product_requests` with status=pending. Admins approve
/// or reject from the admin console.
class ProductRequestScreen extends StatefulWidget {
  const ProductRequestScreen({super.key});

  @override
  State<ProductRequestScreen> createState() => _ProductRequestScreenState();
}

class _ProductRequestScreenState extends State<ProductRequestScreen> {
  final _nameCtrl = TextEditingController();
  final _brandCtrl = TextEditingController();
  final _unitCtrl = TextEditingController();
  final _barcodeCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();
  String _category = 'Tümü';
  String _emoji = '🛒';
  bool _submitting = false;

  static const _emojiPool = [
    '🛒', '🥛', '🍞', '🍳', '🧀', '🍎', '🥬', '🥕', '🍌', '🍊', '🍇',
    '🥦', '🍅', '🍝', '🍚', '🍲', '🫒', '☕', '🍵', '🥤', '🍫', '🍪',
    '🥜', '🧂', '🧼', '🧻', '🧴'
  ];

  @override
  void dispose() {
    _nameCtrl.dispose();
    _brandCtrl.dispose();
    _unitCtrl.dispose();
    _barcodeCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit(AppState state) async {
    final name = _nameCtrl.text.trim();
    if (name.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Geçerli bir ürün adı gir.')),
      );
      return;
    }
    final uid = state.user?.uid ?? '';
    if (uid.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ürün talebi için giriş yap.')),
      );
      return;
    }
    setState(() => _submitting = true);
    try {
      await FirebaseService.instance.productRequests.add({
        'name': name,
        'brand': _brandCtrl.text.trim(),
        'category': _category,
        'unit': _unitCtrl.text.trim(),
        'emoji': _emoji,
        'barcode': _barcodeCtrl.text.trim(),
        'note': _noteCtrl.text.trim(),
        'requestedByUid': uid,
        'requestedByName': state.displayName,
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
      });
      if (!mounted) return;
      _nameCtrl.clear();
      _brandCtrl.clear();
      _unitCtrl.clear();
      _barcodeCtrl.clear();
      _noteCtrl.clear();
      setState(() {
        _category = 'Tümü';
        _emoji = '🛒';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Talebin iletildi. Admin onayı sonrası kataloğa eklenir.'),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Talep gönderilemedi, tekrar dene.')),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = AppStateScope.of(context);
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
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
                  child: FRPageHeader(
                    overline: 'KATALOĞA KATKI',
                    title: 'Ürün',
                    italicTail: ' talebi',
                  ),
                ),
                Expanded(
                  child: ListView(
                    padding: EdgeInsets.fromLTRB(
                      20,
                      16,
                      20,
                      96 +
                          MediaQuery.of(context).viewPadding.bottom +
                          MediaQuery.of(context).viewInsets.bottom +
                          12,
                    ),
                    children: [
                      Text(
                        'Katalogda olmayan bir ürünü öner. Admin onayından sonra herkes bu ürüne fiyat ekleyebilir.',
                        style: frText(13, FontWeight.w500, color: FR.ink3, height: 1.5),
                      ),
                      const SizedBox(height: 18),
                      _label('Ürün adı'),
                      _text(_nameCtrl, 'Tam Yağlı Süt 1L'),
                      const SizedBox(height: 14),
                      _label('Marka'),
                      _text(_brandCtrl, 'Sütaş'),
                      const SizedBox(height: 14),
                      _label('Birim'),
                      _text(_unitCtrl, '1 L / 250 g / 30 adet'),
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
                      _label('Barkod (opsiyonel)'),
                      _text(_barcodeCtrl, '8690…',
                          keyboard: TextInputType.number),
                      const SizedBox(height: 14),
                      _label('Not (opsiyonel)'),
                      _text(_noteCtrl,
                          'Paket, tat, yeni çeşit gibi detaylar',
                          maxLines: 3),
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
                  label: _submitting ? 'Gönderiliyor…' : 'Talebi gönder',
                  icon: Icons.send_rounded,
                  onTap: _submitting ? null : () => _submit(state),
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

  Widget _text(TextEditingController c, String hint,
      {int maxLines = 1, TextInputType? keyboard}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
      decoration: frSurface(radius: FRRad.m),
      child: TextField(
        controller: c,
        maxLines: maxLines,
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
