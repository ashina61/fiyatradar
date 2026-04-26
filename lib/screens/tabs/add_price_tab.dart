import 'package:flutter/material.dart';

import '../../models/product.dart';
import '../../state/app_state.dart';
import '../../ui/components.dart';
import '../../ui/tokens.dart';

class AddPriceTab extends StatefulWidget {
  const AddPriceTab({super.key});

  @override
  State<AddPriceTab> createState() => _AddPriceTabState();
}

class _AddPriceTabState extends State<AddPriceTab> {
  Product? _selectedProduct;
  String? _store;
  final _priceCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();
  final _storeQueryCtrl = TextEditingController();
  bool _submitting = false;

  @override
  void dispose() {
    _priceCtrl.dispose();
    _noteCtrl.dispose();
    _storeQueryCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit(AppState state) async {
    final pid = _selectedProduct?.id;
    final store = _store;
    final price = double.tryParse(_priceCtrl.text.replaceAll(',', '.'));
    if (pid == null || store == null || price == null || price <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ürün, mağaza ve geçerli bir fiyat gir.')),
      );
      return;
    }
    setState(() => _submitting = true);
    try {
      await state.addPrice(
        productId: pid,
        store: store,
        price: price,
        note: _noteCtrl.text.trim(),
      );
      if (!mounted) return;
      _priceCtrl.clear();
      _noteCtrl.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Fiyatı paylaştın · +10 PT · Topluluk doğrulayacak')),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  void _pickProduct(AppState state) async {
    final picked = await showModalBottomSheet<Product>(
      context: context,
      backgroundColor: FR.bg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      isScrollControlled: true,
      builder: (_) => _ProductPicker(products: state.products),
    );
    if (picked != null) setState(() => _selectedProduct = picked);
  }

  @override
  Widget build(BuildContext context) {
    final state = AppStateScope.of(context);
    final storeQuery = _storeQueryCtrl.text.trim().toLowerCase();
    final stores = state.stores;
    final filteredStores = storeQuery.isEmpty
        ? stores
        : stores.where((s) => s.toLowerCase().contains(storeQuery)).toList();

    return SafeArea(
      bottom: false,
      child: Column(
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(20, 14, 20, 0),
            child: FRPageHeader(
              overline: 'TOPLULUĞA KATKI',
              title: 'Fiyat',
              italicTail: ' ekle',
            ),
          ),
          Expanded(
            child: ListView(
              padding: EdgeInsets.fromLTRB(
                20,
                18,
                20,
                frScrollPaddingWithFooter(context),
              ),
              children: [
                _IntroBanner(),
                const SizedBox(height: 18),
                _label('Ürün'),
                InkWell(
                  onTap: () => _pickProduct(state),
                  borderRadius: FRRad.all(FRRad.m),
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: frSurface(radius: FRRad.m),
                    child: Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: FR.bgElev,
                            borderRadius: FRRad.all(10),
                            border: Border.all(color: FR.hairline),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            _selectedProduct?.emoji ?? '🔎',
                            style: const TextStyle(fontSize: 20),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _selectedProduct == null
                              ? Text(
                                  'Onaylı ürünlerde ara…',
                                  style: frText(13, FontWeight.w600, color: FR.ink3),
                                )
                              : Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(_selectedProduct!.name,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: frText(13.5, FontWeight.w800)),
                                    Text(
                                      '${_selectedProduct!.brand} · ${_selectedProduct!.unit}',
                                      style: frText(11.5, FontWeight.w600,
                                          color: FR.ink3),
                                    ),
                                  ],
                                ),
                        ),
                        Icon(Icons.chevron_right_rounded, color: FR.ink3),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                _label('Mağaza / Market'),
                Container(
                  padding: const EdgeInsetsDirectional.fromSTEB(12, 2, 12, 2),
                  decoration: frSurface(radius: FRRad.m),
                  child: TextField(
                    controller: _storeQueryCtrl,
                    onChanged: (_) => setState(() {}),
                    style: frText(13, FontWeight.w700),
                    cursorColor: FR.gold,
                    decoration: InputDecoration(
                      border: InputBorder.none,
                      hintText: 'Market ara…',
                      hintStyle: frText(12.5, FontWeight.w600, color: FR.ink3),
                      prefixIcon: Icon(Icons.search_rounded, color: FR.ink3, size: 18),
                    ),
                  ),
                ),
                _TopStoresStrip(
                  topStores: state.topStoresByFrequency(),
                  selected: _store,
                  onPick: (s) => setState(() => _store = s),
                ),
                const SizedBox(height: 10),
                if (stores.isEmpty)
                  Text(
                    'Aktif market bulunamadı. Admin panelden market ekleyin.',
                    style: frText(12, FontWeight.w600, color: FR.ink3),
                  )
                else if (filteredStores.isEmpty)
                  Text(
                    'Arama ile eşleşen market yok.',
                    style: frText(12, FontWeight.w600, color: FR.ink3),
                  )
                else
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: filteredStores
                        .take(24)
                        .map(
                          (s) => InkWell(
                            onTap: () => setState(() => _store = s),
                            borderRadius: FRRad.all(999),
                            child: Container(
                              padding: const EdgeInsetsDirectional.fromSTEB(
                                  14, 10, 14, 10),
                              decoration: BoxDecoration(
                                color: _store == s ? FR.gold : FR.surface,
                                borderRadius: FRRad.all(999),
                                border: Border.all(
                                  color: _store == s ? FR.gold : FR.hairline,
                                ),
                              ),
                              child: Text(
                                s,
                                style: frText(12, FontWeight.w800,
                                    color: _store == s ? FR.onGold : FR.ink),
                              ),
                            ),
                          ),
                        )
                        .toList(),
                  ),
                const SizedBox(height: 18),
                _label('Fiyat'),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: frSurface(radius: FRRad.m),
                  child: Row(
                    children: [
                      Text('₺',
                          style: frDisplay(22, FontWeight.w700, color: FR.gold)),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextField(
                          controller: _priceCtrl,
                          keyboardType: const TextInputType.numberWithOptions(
                              decimal: true),
                          style: frPrice(28),
                          cursorColor: FR.gold,
                          decoration: InputDecoration(
                            border: InputBorder.none,
                            hintText: '0,00',
                            hintStyle: frPrice(28, color: FR.ink3),
                            isCollapsed: true,
                            contentPadding:
                                const EdgeInsets.symmetric(vertical: 14),
                          ),
                        ),
                      ),
                      Text(
                        _selectedProduct?.unit ?? '',
                        style: frText(12, FontWeight.w700, color: FR.ink3),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                _label('Not (opsiyonel)'),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
                  decoration: frSurface(radius: FRRad.m),
                  child: TextField(
                    controller: _noteCtrl,
                    maxLines: 3,
                    style: frText(13, FontWeight.w600),
                    cursorColor: FR.gold,
                    decoration: InputDecoration(
                      border: InputBorder.none,
                      hintText: 'Kampanya detayı, kupon kodu, stok…',
                      hintStyle: frText(12.5, FontWeight.w600, color: FR.ink3),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                _GuideStrip(),
              ],
            ),
          ),
          SafeArea(
            top: false,
            bottom: true,
            minimum: EdgeInsets.only(
              bottom: frStickyFooterBottomPadding(context),
            ),
            child: Container(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
              decoration: BoxDecoration(
                color: FR.bgElev,
                border: Border(top: BorderSide(color: FR.hairline)),
              ),
              child: FRCta(
                label: _submitting ? 'Gönderiliyor…' : 'Fiyatı paylaş · +10 PT',
                icon: Icons.radar_rounded,
                onTap: _submitting ? null : () => _submit(state),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _label(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Row(
          children: [
            Container(width: 3, height: 14, color: FR.gold),
            const SizedBox(width: 8),
            Text(text, style: frText(12, FontWeight.w800, color: FR.ink, letter: .4)),
          ],
        ),
      );
}

class _TopStoresStrip extends StatelessWidget {
  const _TopStoresStrip({
    required this.topStores,
    required this.selected,
    required this.onPick,
  });
  final List<String> topStores;
  final String? selected;
  final ValueChanged<String> onPick;

  @override
  Widget build(BuildContext context) {
    if (topStores.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.local_fire_department_rounded,
                  size: 14, color: FR.goldDeep),
              const SizedBox(width: 6),
              Text(
                'EN ÇOK PAYLAŞILAN',
                style: frText(10.5, FontWeight.w800,
                    color: FR.ink3, letter: 1.2),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: topStores
                .map(
                  (s) => InkWell(
                    onTap: () => onPick(s),
                    borderRadius: FRRad.all(999),
                    child: Container(
                      padding: const EdgeInsetsDirectional.fromSTEB(
                          12, 8, 12, 8),
                      decoration: BoxDecoration(
                        color: selected == s ? FR.gold : FR.bgElev,
                        borderRadius: FRRad.all(999),
                        border: Border.all(
                          color: selected == s ? FR.gold : FR.hairline,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.storefront_rounded,
                            size: 13,
                            color: selected == s ? FR.onGold : FR.ink2,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            s,
                            style: frText(12, FontWeight.w800,
                                color: selected == s ? FR.onGold : FR.ink),
                          ),
                        ],
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }
}

class _IntroBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [FR.surfaceHi, FR.surfaceLo],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: FRRad.all(22),
        border: Border.all(color: FR.goldDeep.withOpacity(.3)),
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: FR.gold.withOpacity(.15),
              borderRadius: FRRad.all(14),
              border: Border.all(color: FR.goldDeep),
            ),
            child: Icon(Icons.auto_graph_rounded, color: FR.gold, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('RADAR EKOSİSTEMİ', style: frOverline()),
                const SizedBox(height: 4),
                Text('Her paylaşım topluluğu güçlendirir',
                    style: frText(14, FontWeight.w800, height: 1.3)),
                const SizedBox(height: 2),
                Text('Onaylı katkı başına +10 PT',
                    style: frText(11.5, FontWeight.w600, color: FR.ink3)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _GuideStrip extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: FR.surfaceLo,
        borderRadius: FRRad.all(FRRad.m),
        border: Border.all(color: FR.hairline),
      ),
      child: Column(
        children: [
          _row(Icons.photo_camera_outlined, 'Rafta çekilmiş net fotoğraf eklersen onay hızlanır.'),
          const SizedBox(height: 8),
          _row(Icons.verified_user_outlined, 'Sahte fiyat tespit edilirse güven skorun düşer.'),
        ],
      ),
    );
  }

  Widget _row(IconData icon, String text) => Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: FR.ink3, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(text,
                style: frText(11.5, FontWeight.w600, color: FR.ink3, height: 1.45)),
          ),
        ],
      );
}

class _ProductPicker extends StatefulWidget {
  const _ProductPicker({required this.products});
  final List<Product> products;

  @override
  State<_ProductPicker> createState() => _ProductPickerState();
}

class _ProductPickerState extends State<_ProductPicker> {
  String _q = '';

  @override
  Widget build(BuildContext context) {
    final items = widget.products
        .where((p) =>
            _q.isEmpty ||
            p.name.toLowerCase().contains(_q.toLowerCase()) ||
            p.brand.toLowerCase().contains(_q.toLowerCase()))
        .toList();

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: .8,
      maxChildSize: .9,
      builder: (ctx, scrollCtrl) => Container(
        decoration: BoxDecoration(
          color: FR.bg,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 10),
            Container(
              width: 46,
              height: 4,
              decoration: BoxDecoration(
                color: FR.hairline,
                borderRadius: FRRad.all(99),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 6),
              child: Row(
                children: [
                  Expanded(
                    child: Text('Ürün seç',
                        style: frDisplay(22, FontWeight.w700)),
                  ),
                  InkWell(
                    onTap: () => Navigator.pop(context),
                    borderRadius: FRRad.all(999),
                    child: Padding(
                      padding: const EdgeInsets.all(6),
                      child: Icon(Icons.close_rounded, color: FR.ink2),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 6, 20, 10),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                height: 48,
                decoration: frSurface(radius: FRRad.m),
                child: Row(
                  children: [
                    Icon(Icons.search_rounded, color: FR.ink3, size: 19),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        onChanged: (v) => setState(() => _q = v),
                        style: frText(14, FontWeight.w600),
                        cursorColor: FR.gold,
                        decoration: InputDecoration(
                          border: InputBorder.none,
                          isCollapsed: true,
                          hintText: 'Ürün ara…',
                          hintStyle:
                              frText(13, FontWeight.w600, color: FR.ink3),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Expanded(
              child: ListView.separated(
                controller: scrollCtrl,
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 30),
                itemCount: items.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (_, i) {
                  final p = items[i];
                  return InkWell(
                    onTap: () => Navigator.pop(context, p),
                    borderRadius: FRRad.all(FRRad.m),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: frSurface(radius: FRRad.m),
                      child: Row(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: FR.surfaceHi,
                              borderRadius: FRRad.all(10),
                              border: Border.all(color: FR.hairline),
                            ),
                            alignment: Alignment.center,
                            child: Text(p.emoji, style: const TextStyle(fontSize: 20)),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(p.name,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: frText(13.5, FontWeight.w800)),
                                Text('${p.brand} · ${p.unit}',
                                    style: frText(11.5, FontWeight.w600, color: FR.ink3)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
