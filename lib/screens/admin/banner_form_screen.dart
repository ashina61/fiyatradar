import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../models/product.dart';
import '../../services/firebase_service.dart';
import '../../ui/components.dart';
import '../../ui/tokens.dart';

class BannerFormScreen extends StatefulWidget {
  const BannerFormScreen({super.key, this.existing});
  final AppBanner? existing;

  @override
  State<BannerFormScreen> createState() => _BannerFormScreenState();
}

class _BannerFormScreenState extends State<BannerFormScreen> {
  final _titleCtrl = TextEditingController();
  final _subtitleCtrl = TextEditingController();
  final _actionLabelCtrl = TextEditingController(text: 'Keşfet');
  final _orderCtrl = TextEditingController(text: '99');
  final _routeCtrl = TextEditingController();
  String _actionType = 'page'; // 'page' | 'route'
  bool _isActive = true;
  bool _saving = false;
  String? _currentImageUrl;
  String? _currentImagePath;
  Uint8List? _pendingImageBytes;
  List<BannerContentBlock> _blocks = [];

  @override
  void initState() {
    super.initState();
    final b = widget.existing;
    if (b != null) {
      _titleCtrl.text = b.title;
      _subtitleCtrl.text = b.subtitle;
      _actionLabelCtrl.text = b.actionLabel;
      _orderCtrl.text = b.order.toString();
      _actionType = b.actionType.isEmpty ? 'page' : b.actionType;
      _routeCtrl.text = b.actionTarget;
      _currentImageUrl = b.imageUrl;
      _currentImagePath = b.imagePath;
      _blocks = List.of(b.contentBlocks);
    }
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _subtitleCtrl.dispose();
    _actionLabelCtrl.dispose();
    _orderCtrl.dispose();
    _routeCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final x = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1600,
      imageQuality: 85,
    );
    if (x == null) return;
    final bytes = await x.readAsBytes();
    if (!mounted) return;
    setState(() => _pendingImageBytes = bytes);
  }

  void _addBlock(String type) {
    setState(() => _blocks.add(BannerContentBlock(type: type, value: '')));
  }

  void _moveBlock(int from, int to) {
    if (to < 0 || to >= _blocks.length) return;
    setState(() {
      final b = _blocks.removeAt(from);
      _blocks.insert(to, b);
    });
  }

  void _removeBlock(int i) {
    setState(() => _blocks.removeAt(i));
  }

  Future<void> _save() async {
    final title = _titleCtrl.text.trim();
    if (title.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Başlık en az 2 karakter olmalı.')),
      );
      return;
    }
    setState(() => _saving = true);
    try {
      final docRef = widget.existing == null
          ? FirebaseService.instance.banners.doc()
          : FirebaseService.instance.banners.doc(widget.existing!.id);

      String? newImageUrl = _currentImageUrl;
      String? newImagePath = _currentImagePath;
      if (_pendingImageBytes != null) {
        final res = await FirebaseService.instance.uploadBannerImage(
          bannerId: docRef.id,
          bytes: _pendingImageBytes!,
        );
        newImageUrl = res.url;
        newImagePath = res.path;
      }

      final blocks = _blocks
          .where((b) => b.value.trim().isNotEmpty)
          .map((b) => b.toMap())
          .toList();

      final payload = <String, dynamic>{
        'title': title,
        'subtitle': _subtitleCtrl.text.trim(),
        'actionLabel': _actionLabelCtrl.text.trim().isEmpty
            ? 'Keşfet'
            : _actionLabelCtrl.text.trim(),
        'order': int.tryParse(_orderCtrl.text.trim()) ?? 99,
        'isActive': _isActive,
        'actionType': _actionType,
        'actionTarget':
            _actionType == 'route' ? _routeCtrl.text.trim() : '',
        'contentBlocks': blocks,
        if (newImageUrl != null) 'imageUrl': newImageUrl,
        if (newImagePath != null) 'imagePath': newImagePath,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      await docRef.set(payload, SetOptions(merge: true));

      // Clean up replaced image.
      if (_pendingImageBytes != null &&
          _currentImagePath != null &&
          _currentImagePath!.isNotEmpty &&
          _currentImagePath != newImagePath) {
        await FirebaseService.instance.deleteStorageFile(_currentImagePath!);
      }

      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(widget.existing == null
              ? 'Banner oluşturuldu.'
              : 'Banner güncellendi.'),
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

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.existing != null;
    return Scaffold(
      backgroundColor: FR.bg,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 0), // LEGACY_EXCEPTION: reason=token_migration owner=codex remove_by=2026-06-30
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
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 0), // LEGACY_EXCEPTION: reason=token_migration owner=codex remove_by=2026-06-30
              child: FRPageHeader(
                overline: isEdit ? 'DÜZENLE' : 'YENİ BANNER',
                title: 'Banner',
                italicTail: isEdit ? ' düzenle' : ' ekle',
              ),
            ),
            Expanded(
              child: ListView(
                padding: EdgeInsets.fromLTRB( // LEGACY_EXCEPTION: reason=token_migration owner=codex remove_by=2026-06-30
                  20,
                  18,
                  20,
                  20 + MediaQuery.of(context).viewInsets.bottom,
                ),
                children: [
                  _bannerImageBlock(),
                  const SizedBox(height: 14),
                  _label('Başlık'),
                  _input(_titleCtrl, 'Markette gördüğünü paylaş'),
                  const SizedBox(height: 12),
                  _label('Alt başlık'),
                  _input(_subtitleCtrl, 'Her paylaşım +10 puan'),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _label('Buton metni'),
                            _input(_actionLabelCtrl, 'Keşfet'),
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),
                      SizedBox(
                        width: 90,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _label('Sıra'),
                            _input(_orderCtrl, '1',
                                keyboard: TextInputType.number),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _label('Tıklayınca ne olsun?'),
                  Row(
                    children: [
                      Expanded(
                        child: _typeChip(
                          label: 'İçerik sayfası',
                          icon: Icons.menu_book_rounded,
                          active: _actionType == 'page',
                          onTap: () => setState(() => _actionType = 'page'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _typeChip(
                          label: 'Yönlendirme',
                          icon: Icons.alt_route_rounded,
                          active: _actionType == 'route',
                          onTap: () => setState(() => _actionType = 'route'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (_actionType == 'route') ...[
                    _label('Yönlendirme hedefi'),
                    _input(_routeCtrl,
                        'cheapest · newest · favorites · category:İçecek · home · explore · basket · profile'),
                    const SizedBox(height: 6),
                    Text(
                      'cheapest = en ucuz · newest = yeni · category:<ad> = kategoriyle keşfet',
                      style: frText(11, FontWeight.w600, color: FR.ink3),
                    ),
                  ] else ...[
                    _label('İçerik blokları (yazı / görsel / başlık)'),
                    Container(
                      padding: const EdgeInsets.all(10), // LEGACY_EXCEPTION: reason=token_migration owner=codex remove_by=2026-06-30
                      decoration: frSurface(radius: FRRad.m),
                      child: Column(
                        children: [
                          for (var i = 0; i < _blocks.length; i++)
                            _BlockEditor(
                              key: ValueKey('blk_$i'),
                              block: _blocks[i],
                              onChanged: (b) =>
                                  setState(() => _blocks[i] = b),
                              onRemove: () => _removeBlock(i),
                              onMoveUp: i > 0
                                  ? () => _moveBlock(i, i - 1)
                                  : null,
                              onMoveDown: i < _blocks.length - 1
                                  ? () => _moveBlock(i, i + 1)
                                  : null,
                            ),
                          if (_blocks.isEmpty)
                            Padding(
                              padding: const EdgeInsets.all(12), // LEGACY_EXCEPTION: reason=token_migration owner=codex remove_by=2026-06-30
                              child: Text(
                                'Boş içerik. Aşağıdaki butonlardan blok ekle.',
                                style: frText(12, FontWeight.w600, color: FR.ink3),
                              ),
                            ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Expanded(
                                child: FRCta(
                                  label: '+ Başlık',
                                  filled: false,
                                  onTap: () => _addBlock('heading'),
                                ),
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: FRCta(
                                  label: '+ Yazı',
                                  filled: false,
                                  onTap: () => _addBlock('text'),
                                ),
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: FRCta(
                                  label: '+ Görsel',
                                  filled: false,
                                  onTap: () => _addBlock('image'),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Switch(
                        value: _isActive,
                        onChanged: (v) => setState(() => _isActive = v),
                        activeColor: FR.bg,
                        activeTrackColor: FR.gold,
                        inactiveThumbColor: FR.ink2,
                        inactiveTrackColor: FR.surfaceHi,
                      ),
                      const SizedBox(width: 8),
                      Text(_isActive ? 'Yayında' : 'Pasif',
                          style: frText(13, FontWeight.w800,
                              color: _isActive ? FR.good : FR.ink3)),
                    ],
                  ),
                  const SizedBox(height: 18),
                  FRCta(
                    label: _saving ? 'Kaydediliyor…' : 'Kaydet',
                    icon: Icons.check_rounded,
                    onTap: _saving ? null : _save,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _bannerImageBlock() {
    final hasPending = _pendingImageBytes != null;
    final hasCurrent =
        _currentImageUrl != null && _currentImageUrl!.isNotEmpty;
    return InkWell(
      onTap: _saving ? null : _pickImage,
      borderRadius: FRRad.all(FRRad.l),
      child: Container(
        height: 140,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: FR.surfaceHi,
          borderRadius: FRRad.all(FRRad.l),
          border: Border.all(color: FR.hairline),
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (hasPending)
              Image.memory(_pendingImageBytes!, fit: BoxFit.cover)
            else if (hasCurrent)
              Image.network(
                _currentImageUrl!,
                fit: BoxFit.cover,
                cacheWidth: 1200,
                filterQuality: FilterQuality.medium,
                errorBuilder: (_, __, ___) =>
                    Icon(Icons.broken_image_outlined, color: FR.ink3),
              )
            else
              Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.image_outlined, size: 28, color: FR.gold),
                    const SizedBox(height: 6),
                    Text('Banner görseli seç',
                        style: frText(12.5, FontWeight.w800, color: FR.ink2)),
                    Text('opsiyonel — boş bırakırsan ikon gösterilir',
                        style: frText(10.5, FontWeight.w600, color: FR.ink3)),
                  ],
                ),
              ),
            Positioned(
              right: 10,
              bottom: 10,
              child: Container(
                padding: const EdgeInsets.symmetric( // LEGACY_EXCEPTION: reason=token_migration owner=codex remove_by=2026-06-30
                    horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: FR.bg.withOpacity(.7),
                  borderRadius: FRRad.all(999),
                  border: Border.all(color: FR.hairline),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.edit_outlined, size: 13, color: FR.gold),
                    const SizedBox(width: 4),
                    Text('Görseli değiştir',
                        style: frText(11, FontWeight.w800, color: FR.ink)),
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
        padding: const EdgeInsets.only(bottom: 6, top: 4), // LEGACY_EXCEPTION: reason=token_migration owner=codex remove_by=2026-06-30
        child: Text(text,
            style: frText(11.5, FontWeight.w800, color: FR.ink3, letter: .4)),
      );

  Widget _input(TextEditingController c, String hint, {TextInputType? keyboard}) {
    return TextField(
      controller: c,
      keyboardType: keyboard,
      style: frText(14, FontWeight.w700),
      cursorColor: FR.gold,
      decoration: InputDecoration(hintText: hint),
    );
  }

  Widget _typeChip({
    required String label,
    required IconData icon,
    required bool active,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: FRRad.all(FRRad.m),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12), // LEGACY_EXCEPTION: reason=token_migration owner=codex remove_by=2026-06-30
        decoration: BoxDecoration(
          color: active ? FR.gold.withOpacity(.16) : FR.surfaceHi,
          borderRadius: FRRad.all(FRRad.m),
          border: Border.all(color: active ? FR.gold : FR.hairline),
        ),
        child: Row(
          children: [
            Icon(icon, color: active ? FR.gold : FR.ink2, size: 16),
            const SizedBox(width: 8),
            Text(label,
                style: frText(12.5, FontWeight.w800,
                    color: active ? FR.gold : FR.ink2)),
          ],
        ),
      ),
    );
  }
}

class _BlockEditor extends StatefulWidget {
  const _BlockEditor({
    super.key,
    required this.block,
    required this.onChanged,
    required this.onRemove,
    this.onMoveUp,
    this.onMoveDown,
  });
  final BannerContentBlock block;
  final ValueChanged<BannerContentBlock> onChanged;
  final VoidCallback onRemove;
  final VoidCallback? onMoveUp;
  final VoidCallback? onMoveDown;

  @override
  State<_BlockEditor> createState() => _BlockEditorState();
}

class _BlockEditorState extends State<_BlockEditor> {
  late final TextEditingController _ctrl =
      TextEditingController(text: widget.block.value);

  @override
  void didUpdateWidget(covariant _BlockEditor old) {
    super.didUpdateWidget(old);
    if (old.block.value != widget.block.value && _ctrl.text != widget.block.value) {
      _ctrl.text = widget.block.value;
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  String get _label {
    switch (widget.block.type) {
      case 'heading':
        return 'BAŞLIK';
      case 'image':
        return 'GÖRSEL URL';
      case 'text':
      default:
        return 'YAZI';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8), // LEGACY_EXCEPTION: reason=token_migration owner=codex remove_by=2026-06-30
      padding: const EdgeInsets.all(10), // LEGACY_EXCEPTION: reason=token_migration owner=codex remove_by=2026-06-30
      decoration: BoxDecoration(
        color: FR.bgElev,
        borderRadius: FRRad.all(FRRad.m),
        border: Border.all(color: FR.hairline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(_label,
                  style: frOverline(color: FR.gold, size: 9.5)),
              const Spacer(),
              IconButton(
                onPressed: widget.onMoveUp,
                icon: Icon(Icons.arrow_upward_rounded,
                    size: 16,
                    color: widget.onMoveUp == null ? FR.ink3 : FR.ink2),
                padding: EdgeInsets.zero, // LEGACY_EXCEPTION: reason=token_migration owner=codex remove_by=2026-06-30
                constraints:
                    const BoxConstraints(minWidth: 28, minHeight: 28),
              ),
              IconButton(
                onPressed: widget.onMoveDown,
                icon: Icon(Icons.arrow_downward_rounded,
                    size: 16,
                    color: widget.onMoveDown == null ? FR.ink3 : FR.ink2),
                padding: EdgeInsets.zero, // LEGACY_EXCEPTION: reason=token_migration owner=codex remove_by=2026-06-30
                constraints:
                    const BoxConstraints(minWidth: 28, minHeight: 28),
              ),
              IconButton(
                onPressed: widget.onRemove,
                icon: Icon(Icons.delete_outline_rounded,
                    size: 16, color: FR.bad),
                padding: EdgeInsets.zero, // LEGACY_EXCEPTION: reason=token_migration owner=codex remove_by=2026-06-30
                constraints:
                    const BoxConstraints(minWidth: 28, minHeight: 28),
              ),
            ],
          ),
          TextField(
            controller: _ctrl,
            maxLines: widget.block.type == 'text' ? 4 : 1,
            style: frText(13, FontWeight.w700),
            cursorColor: FR.gold,
            decoration: InputDecoration(
              hintText: widget.block.type == 'image'
                  ? 'https://… (banner sayfasında gösterilecek görsel)'
                  : widget.block.type == 'heading'
                      ? 'Bölüm başlığı'
                      : 'Paragraf metni',
            ),
            onChanged: (v) => widget.onChanged(
              BannerContentBlock(type: widget.block.type, value: v),
            ),
          ),
        ],
      ),
    );
  }
}

