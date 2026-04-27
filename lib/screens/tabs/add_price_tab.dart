import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';

import '../../models/price_v1.dart';
import '../../models/product.dart';
import '../../services/firebase_service.dart';
import '../../state/app_state.dart';
import '../../ui/components.dart';
import '../../ui/tokens.dart';

class AddPriceTab extends StatefulWidget {
  const AddPriceTab({super.key});

  @override
  State<AddPriceTab> createState() => _AddPriceTabState();
}

class _AddPriceTabState extends State<AddPriceTab> {
  static const _kStoreResultLimit = 30;
  Product? _selectedProduct;
  StorePlace? _selectedPlace;
  PriceSourceType _sourceType = PriceSourceType.physical;
  final _priceCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();
  final _storeQueryCtrl = TextEditingController();
  bool _submitting = false;
  bool _locating = false;
  double? _regionLat;
  double? _regionLng;

  bool get _needsRegion => _sourceType != PriceSourceType.online;

  @override
  void initState() {
    super.initState();
    _ensureOnlinePlacesBootstrapped();
  }

  @override
  void dispose() {
    _priceCtrl.dispose();
    _noteCtrl.dispose();
    _storeQueryCtrl.dispose();
    super.dispose();
  }

  Future<void> _ensureOnlinePlacesBootstrapped() async {
    try {
      await FirebaseService.instance.seedDefaultOnlinePlaces();
    } catch (_) {
      // non-admin/limited sessions are allowed to continue.
    }
  }

  Future<void> _submit(AppState state) async {
    final pid = _selectedProduct?.id;
    final place = _selectedPlace;
    final price = double.tryParse(_priceCtrl.text.replaceAll(',', '.'));
    final city = (state.cityName ?? '').trim();
    final district = (state.districtName ?? '').trim();

    if (pid == null || price == null || price <= 0) {
      _snack('Ürün seçip geçerli bir fiyat girmelisin.');
      return;
    }
    if (place == null) {
      _snack('Fiyatı göndermeden önce bir kaynak seçmelisin.');
      return;
    }
    if (_needsRegion && (city.isEmpty || district.isEmpty)) {
      _snack('Fiziksel/Pazar fiyatı için şehir ve ilçe zorunlu.');
      return;
    }

    setState(() => _submitting = true);
    try {
      await state.addPrice(
        productId: pid,
        store: place.displayName,
        price: price,
        note: _noteCtrl.text.trim(),
        placeId: place.id,
        city: _needsRegion ? city : null,
        district: _needsRegion ? district : null,
        sourceType: _sourceType,
        chainId: place.chainId,
        chainName: place.chainName,
        lat: _needsRegion ? _regionLat : null,
        lng: _needsRegion ? _regionLng : null,
      );
      if (!mounted) return;
      _priceCtrl.clear();
      _noteCtrl.clear();
      _snack('Fiyatı paylaştın · +10 PT · Topluluk doğrulayacak');
    } catch (e) {
      if (!mounted) return;
      _snack('Fiyat gönderilemedi: $e');
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  void _snack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
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

  Future<void> _useCurrentLocation(AppState state) async {
    setState(() => _locating = true);
    try {
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        _snack('Konum izni olmadan bölge belirlenemedi. İl/ilçe seçebilirsin.');
        await _pickRegionManually(state);
        return;
      }
      final pos = await Geolocator.getCurrentPosition();
      _regionLat = pos.latitude;
      _regionLng = pos.longitude;
      try {
        final places = await placemarkFromCoordinates(pos.latitude, pos.longitude);
        final mark = places.isNotEmpty ? places.first : null;
        final city = (mark?.administrativeArea ?? mark?.locality ?? '').trim();
        final district = (mark?.subAdministrativeArea ?? mark?.subLocality ?? '').trim();
        if (city.isEmpty || district.isEmpty) {
          _snack('Konum çözümlendi ama il/ilçe bulunamadı. Elle seçmelisin.');
          await _pickRegionManually(state);
          return;
        }
        await state.updateRegionSettings(cityName: city, districtName: district);
        if (!mounted) return;
        _snack('Bölge ayarlandı: $city / $district');
      } catch (_) {
        _snack('Konumdan il/ilçe alınamadı. Elle seçebilirsin.');
        await _pickRegionManually(state);
      }
    } catch (e) {
      _snack('Konum alınamadı: $e');
      await _pickRegionManually(state);
    } finally {
      if (mounted) setState(() => _locating = false);
    }
  }

  Future<void> _pickRegionManually(AppState state) async {
    final result = await showModalBottomSheet<(String, String)?>(
      context: context,
      isScrollControlled: true,
      backgroundColor: FR.bg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _RegionPickerSheet(
        initialCity: state.cityName,
        initialDistrict: state.districtName,
      ),
    );
    if (result == null) return;
    await state.updateRegionSettings(cityName: result.$1, districtName: result.$2);
    if (!mounted) return;
    _snack('Bölge ayarlandı: ${result.$1} / ${result.$2}');
  }

  Query<Map<String, dynamic>> _basePlaceQuery(AppState state, {required bool search}) {
    final coll = FirebaseService.instance.storePlaces;
    final city = (state.cityName ?? '').trim();
    final district = (state.districtName ?? '').trim();

    Query<Map<String, dynamic>> q = coll.where('isActive', isEqualTo: true);

    if (_sourceType == PriceSourceType.online) {
      q = q
          .where('type', isEqualTo: 'online_market')
          .where('status', whereIn: const ['verified', 'trusted']);
    } else {
      q = _sourceType == PriceSourceType.physical
          ? q.where('type', whereIn: const ['chain_market', 'local_market'])
          : q.where('type', isEqualTo: 'bazaar');
      q = q.where('city', isEqualTo: city).where('district', isEqualTo: district);
      q = q.where('status', whereIn: const ['verified', 'trusted']);
    }

    final searchText = _storeQueryCtrl.text.trim().toLowerCase();
    if (search && searchText.isNotEmpty) {
      return q
          .orderBy('normalizedName')
          .startAt([searchText]).endAt(['$searchText\uf8ff']).limit(_kStoreResultLimit);
    }
    return q.orderBy('usageCount', descending: true).limit(_kStoreResultLimit);
  }

  Stream<List<StorePlace>> _placeStream(AppState state) async* {
    final needsRegion = _needsRegion;
    if (needsRegion &&
        ((state.cityName ?? '').trim().isEmpty || (state.districtName ?? '').trim().isEmpty)) {
      yield const <StorePlace>[];
      return;
    }

    final ownUid = state.user?.uid;
    final hasSearch = _storeQueryCtrl.text.trim().isNotEmpty;
    final normalQuery = _basePlaceQuery(state, search: hasSearch);
    final normalSnap = await normalQuery.get();
    final all = <String, StorePlace>{
      for (final d in normalSnap.docs) d.id: StorePlace.fromDoc(d),
    };

    if (_sourceType != PriceSourceType.online && ownUid != null && ownUid.isNotEmpty) {
      final city = (state.cityName ?? '').trim();
      final district = (state.districtName ?? '').trim();
      final ownPendingQ = FirebaseService.instance.storePlaces
          .where('isActive', isEqualTo: true)
          .where('createdByUid', isEqualTo: ownUid)
          .where('status', isEqualTo: 'pending')
          .where('city', isEqualTo: city)
          .where('district', isEqualTo: district)
          .limit(_kStoreResultLimit);
      final ownPendingSnap = await ownPendingQ.get();
      for (final d in ownPendingSnap.docs) {
        final place = StorePlace.fromDoc(d);
        if (_sourceType == PriceSourceType.physical &&
            !(place.type == StorePlaceType.chainMarket || place.type == StorePlaceType.localMarket)) {
          continue;
        }
        if (_sourceType == PriceSourceType.bazaar && place.type != StorePlaceType.bazaar) {
          continue;
        }
        all[d.id] = place;
      }
    }

    final list = all.values.toList()
      ..sort((a, b) => a.displayName.toLowerCase().compareTo(b.displayName.toLowerCase()));
    yield list.take(_kStoreResultLimit).toList();
  }

  Future<void> _openSuggestPlaceSheet(AppState state) async {
    final place = await showModalBottomSheet<StorePlace?>(
      context: context,
      isScrollControlled: true,
      backgroundColor: FR.bg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _SuggestPlaceSheet(
        sourceType: _sourceType,
        city: state.cityName,
        district: state.districtName,
      ),
    );
    if (place == null) return;
    setState(() => _selectedPlace = place);
    _snack('Öneri kaydedildi ve seçildi.');
  }

  @override
  Widget build(BuildContext context) {
    final state = AppStateScope.of(context);
    final city = (state.cityName ?? '').trim();
    final district = (state.districtName ?? '').trim();
    final regionMissing = _needsRegion && (city.isEmpty || district.isEmpty);

    return SafeArea(
      bottom: false,
      child: Column(
        children: [
          const Padding(
            padding: EdgeInsetsDirectional.fromSTEB(FRSpace.xl, 14, FRSpace.xl, 0),
            child: FRPageHeader(overline: 'TOPLULUĞA KATKI', title: 'Fiyat', italicTail: ' ekle'),
          ),
          Expanded(
            child: ListView(
              padding: EdgeInsets.fromLTRB(20, 18, 20, frScrollPaddingWithFooter(context)), // LEGACY_EXCEPTION: reason=token_migration owner=codex remove_by=2026-06-30
              children: [
                _IntroBanner(),
                const SizedBox(height: 18),
                _label('Ürün'),
                InkWell(
                  onTap: () => _pickProduct(state),
                  borderRadius: FRRad.all(FRRad.m),
                  child: Container(
                    padding: const EdgeInsets.all(14), // LEGACY_EXCEPTION: reason=token_migration owner=codex remove_by=2026-06-30
                    decoration: frSurface(radius: FRRad.m),
                    child: Row(children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: FR.bgElev,
                          borderRadius: FRRad.all(10),
                          border: Border.all(color: FR.hairline),
                        ),
                        alignment: Alignment.center,
                        child: Text(_selectedProduct?.emoji ?? '🔎', style: const TextStyle(fontSize: 20)),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _selectedProduct == null
                            ? Text('Onaylı ürünlerde ara…', style: frText(13, FontWeight.w600, color: FR.ink3))
                            : Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                Text(_selectedProduct!.name,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: frText(13.5, FontWeight.w800)),
                                Text('${_selectedProduct!.brand} · ${_selectedProduct!.unit}',
                                    style: frText(11.5, FontWeight.w600, color: FR.ink3)),
                              ]),
                      ),
                      Icon(Icons.chevron_right_rounded, color: FR.ink3),
                    ]),
                  ),
                ),
                const SizedBox(height: 18),
                _label('Kaynak türü'),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _sourceChip('Fiziksel Market', PriceSourceType.physical),
                    _sourceChip('Online Market', PriceSourceType.online),
                    _sourceChip('Pazar', PriceSourceType.bazaar),
                  ],
                ),
                const SizedBox(height: 18),
                if (_needsRegion) ...[
                  _label('Bölge'),
                  if (city.isNotEmpty && district.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.all(12), // LEGACY_EXCEPTION: reason=token_migration owner=codex remove_by=2026-06-30
                      decoration: frSurface(radius: FRRad.m),
                      child: Row(children: [
                        Icon(Icons.location_on_rounded, color: FR.gold, size: 18),
                        const SizedBox(width: 8),
                        Expanded(child: Text('$city / $district', style: frText(13, FontWeight.w700))),
                        TextButton(
                          onPressed: () => _pickRegionManually(state),
                          child: Text('Değiştir', style: frText(12, FontWeight.w700, color: FR.gold)),
                        )
                      ]),
                    )
                  else
                    Container(
                      padding: const EdgeInsets.all(14), // LEGACY_EXCEPTION: reason=token_migration owner=codex remove_by=2026-06-30
                      decoration: frSurface(radius: FRRad.m),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text('Fiyat eklemek için bölge seçmelisin.', style: frText(12.5, FontWeight.w700)),
                        const SizedBox(height: 12),
                        Wrap(spacing: 8, runSpacing: 8, children: [
                          FRCta(
                            label: _locating ? 'Konum alınıyor…' : 'Konumumu kullan',
                            icon: Icons.my_location_rounded,
                            onTap: _locating ? null : () => _useCurrentLocation(state),
                          ),
                          FRCta(
                            label: 'İl / ilçe seç',
                            icon: Icons.map_outlined,
                            onTap: () => _pickRegionManually(state),
                          ),
                        ]),
                      ]),
                    ),
                  const SizedBox(height: 18),
                ],
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
                const SizedBox(height: 10),
                if (regionMissing)
                  _missingRegionEmpty(state)
                else
                  StreamBuilder<List<StorePlace>>(
                    stream: _placeStream(state),
                    builder: (context, snapshot) {
                      final places = snapshot.data ?? const <StorePlace>[];
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return Text('Kayıtlar yükleniyor…', style: frText(12, FontWeight.w600, color: FR.ink3));
                      }
                      if (places.isEmpty) {
                        return _placesEmpty(state);
                      }
                      return Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: places.map((place) {
                          final selected = _selectedPlace?.id == place.id;
                          return InkWell(
                            onTap: () => setState(() => _selectedPlace = place),
                            borderRadius: FRRad.all(999),
                            child: Container(
                              padding: const EdgeInsetsDirectional.fromSTEB(14, 10, 14, 10),
                              decoration: BoxDecoration(
                                color: selected ? FR.gold : FR.surface,
                                borderRadius: FRRad.all(999),
                                border: Border.all(color: selected ? FR.gold : FR.hairline),
                              ),
                              child: Text(place.displayName,
                                  style: frText(12, FontWeight.w800, color: selected ? FR.onGold : FR.ink)),
                            ),
                          );
                        }).toList(),
                      );
                    },
                  ),
                const SizedBox(height: 18),
                _label('Fiyat'),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8), // LEGACY_EXCEPTION: reason=token_migration owner=codex remove_by=2026-06-30
                  decoration: frSurface(radius: FRRad.m),
                  child: Row(children: [
                    Text('₺', style: frDisplay(22, FontWeight.w700, color: FR.gold)),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        controller: _priceCtrl,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        style: frPrice(28),
                        cursorColor: FR.gold,
                        decoration: InputDecoration(
                          border: InputBorder.none,
                          hintText: '0,00',
                          hintStyle: frPrice(28, color: FR.ink3),
                          isCollapsed: true,
                          contentPadding: const EdgeInsets.symmetric(vertical: 14), // LEGACY_EXCEPTION: reason=token_migration owner=codex remove_by=2026-06-30
                        ),
                      ),
                    ),
                    Text(_selectedProduct?.unit ?? '', style: frText(12, FontWeight.w700, color: FR.ink3)),
                  ]),
                ),
                const SizedBox(height: 18),
                _label('Not (opsiyonel)'),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2), // LEGACY_EXCEPTION: reason=token_migration owner=codex remove_by=2026-06-30
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
            minimum: EdgeInsets.only(bottom: frStickyFooterBottomPadding(context)), // LEGACY_EXCEPTION: reason=token_migration owner=codex remove_by=2026-06-30
            child: Container(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 8), // LEGACY_EXCEPTION: reason=token_migration owner=codex remove_by=2026-06-30
              decoration: BoxDecoration(color: FR.bgElev, border: Border(top: BorderSide(color: FR.hairline))),
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

  Widget _missingRegionEmpty(AppState state) => Container(
        padding: const EdgeInsets.all(14), // LEGACY_EXCEPTION: reason=token_migration owner=codex remove_by=2026-06-30
        decoration: frSurface(radius: FRRad.m),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Bölge seçmelisin.', style: frText(12.5, FontWeight.w700, color: FR.ink3)),
          const SizedBox(height: 10),
          Wrap(spacing: 8, runSpacing: 8, children: [
            FRCta(
              label: _locating ? 'Konum alınıyor…' : 'Konumumu kullan',
              icon: Icons.my_location_rounded,
              onTap: _locating ? null : () => _useCurrentLocation(state),
            ),
            FRCta(label: 'İl / ilçe seç', icon: Icons.map_outlined, onTap: () => _pickRegionManually(state)),
          ]),
        ]),
      );

  Widget _placesEmpty(AppState state) {
    final hasSearch = _storeQueryCtrl.text.trim().isNotEmpty;
    final isOnline = _sourceType == PriceSourceType.online;
    final isBazaar = _sourceType == PriceSourceType.bazaar;
    final title = isOnline
        ? 'Online market kaydı yok.'
        : isBazaar
            ? (hasSearch
                ? 'Arama ile eşleşen pazar yok.'
                : 'Bu bölgede kayıtlı pazar yok.')
            : (hasSearch
                ? 'Arama ile eşleşen market yok.'
                : 'Bu bölgede kayıtlı market yok.');
    final suggestLabel = isBazaar ? 'Bu pazarı öner' : 'Bu marketi öner';
    return Container(
      padding: const EdgeInsets.all(14), // LEGACY_EXCEPTION: reason=token_migration owner=codex remove_by=2026-06-30
      decoration: frSurface(radius: FRRad.m),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: frText(12.5, FontWeight.w700, color: FR.ink3)),
        const SizedBox(height: 10),
        if (!isOnline || state.isAdmin)
          FRCta(
            label: suggestLabel,
            icon: Icons.add_business_rounded,
            onTap: _submitting ? null : () => _openSuggestPlaceSheet(state),
          )
      ]),
    );
  }

  Widget _label(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 10), // LEGACY_EXCEPTION: reason=token_migration owner=codex remove_by=2026-06-30
        child: Row(children: [
          Container(width: 3, height: 14, color: FR.gold),
          const SizedBox(width: 8),
          Text(text, style: frText(12, FontWeight.w800, color: FR.ink, letter: .4)),
        ]),
      );

  Widget _sourceChip(String label, PriceSourceType type) {
    final selected = _sourceType == type;
    return InkWell(
      onTap: () => setState(() {
        _sourceType = type;
        _selectedPlace = null;
        if (_sourceType == PriceSourceType.online) {
          _ensureOnlinePlacesBootstrapped();
        }
      }),
      borderRadius: FRRad.all(999),
      child: Container(
        padding: const EdgeInsetsDirectional.fromSTEB(14, 10, 14, 10),
        decoration: BoxDecoration(
          color: selected ? FR.gold : FR.surface,
          borderRadius: FRRad.all(999),
          border: Border.all(color: selected ? FR.gold : FR.hairline),
        ),
        child: Text(label, style: frText(12, FontWeight.w800, color: selected ? FR.onGold : FR.ink)),
      ),
    );
  }
}

class _RegionPickerSheet extends StatefulWidget {
  const _RegionPickerSheet({this.initialCity, this.initialDistrict});
  final String? initialCity;
  final String? initialDistrict;

  @override
  State<_RegionPickerSheet> createState() => _RegionPickerSheetState();
}

class _RegionPickerSheetState extends State<_RegionPickerSheet> {
  late final TextEditingController _cityCtrl;
  late final TextEditingController _districtCtrl;

  @override
  void initState() {
    super.initState();
    _cityCtrl = TextEditingController(text: widget.initialCity ?? '');
    _districtCtrl = TextEditingController(text: widget.initialDistrict ?? '');
  }

  @override
  void dispose() {
    _cityCtrl.dispose();
    _districtCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only( // LEGACY_EXCEPTION: reason=token_migration owner=codex remove_by=2026-06-30
        left: 20,
        right: 20,
        top: 20,
        bottom: 20 + MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('İl / ilçe seç', style: frDisplay(20, FontWeight.w700)),
        const SizedBox(height: 12),
        TextField(controller: _cityCtrl, decoration: const InputDecoration(labelText: 'İl')),
        const SizedBox(height: 10),
        TextField(controller: _districtCtrl, decoration: const InputDecoration(labelText: 'İlçe')),
        const SizedBox(height: 12),
        FRCta(
          label: 'Kaydet',
          icon: Icons.check_rounded,
          onTap: () {
            final city = _cityCtrl.text.trim();
            final district = _districtCtrl.text.trim();
            if (city.isEmpty || district.isEmpty) {
              ScaffoldMessenger.of(context)
                  .showSnackBar(const SnackBar(content: Text('İl ve ilçe zorunlu.')));
              return;
            }
            Navigator.pop(context, (city, district));
          },
        ),
      ]),
    );
  }
}

class _SuggestPlaceSheet extends StatefulWidget {
  const _SuggestPlaceSheet({required this.sourceType, this.city, this.district});
  final PriceSourceType sourceType;
  final String? city;
  final String? district;

  @override
  State<_SuggestPlaceSheet> createState() => _SuggestPlaceSheetState();
}

class _SuggestPlaceSheetState extends State<_SuggestPlaceSheet> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _cityCtrl;
  late final TextEditingController _districtCtrl;
  final TextEditingController _neighborhoodCtrl = TextEditingController();
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController();
    _cityCtrl = TextEditingController(text: widget.city ?? '');
    _districtCtrl = TextEditingController(text: widget.district ?? '');
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _cityCtrl.dispose();
    _districtCtrl.dispose();
    _neighborhoodCtrl.dispose();
    super.dispose();
  }

  String _normalize(String value) => value.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');

  String _typeString() {
    switch (widget.sourceType) {
      case PriceSourceType.physical:
        return 'local_market';
      case PriceSourceType.online:
        return 'online_market';
      case PriceSourceType.bazaar:
        return 'bazaar';
    }
  }

  Future<void> _save() async {
    final state = AppStateScope.of(context);
    final uid = state.user?.uid;
    if (uid == null || uid.isEmpty) return;
    final name = _nameCtrl.text.trim().replaceAll(RegExp(r'\s+'), ' ');
    final normalized = _normalize(name);
    final city = _cityCtrl.text.trim();
    final district = _districtCtrl.text.trim();
    final type = _typeString();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Ad zorunlu.')));
      return;
    }
    if (widget.sourceType != PriceSourceType.online && (city.isEmpty || district.isEmpty)) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Fiziksel/Pazar için il/ilçe zorunlu.')));
      return;
    }

    setState(() => _saving = true);
    try {
      final coll = FirebaseService.instance.storePlaces;
      final dupByNormalized = await coll
          .where('type', isEqualTo: type)
          .where('city', isEqualTo: city)
          .where('district', isEqualTo: district)
          .where('normalizedName', isEqualTo: normalized)
          .limit(1)
          .get();
      if (dupByNormalized.docs.isNotEmpty) {
        if (!mounted) return;
        Navigator.pop(context, StorePlace.fromDoc(dupByNormalized.docs.first));
        return;
      }
      final dupByDisplay = await coll
          .where('type', isEqualTo: type)
          .where('city', isEqualTo: city)
          .where('district', isEqualTo: district)
          .where('displayName', isEqualTo: name)
          .limit(1)
          .get();
      if (dupByDisplay.docs.isNotEmpty) {
        if (!mounted) return;
        Navigator.pop(context, StorePlace.fromDoc(dupByDisplay.docs.first));
        return;
      }
      final now = FieldValue.serverTimestamp();
      final ref = await coll.add({
        'chainId': null,
        'chainName': null,
        'type': type,
        'displayName': name,
        'normalizedName': normalized,
        'city': city,
        'district': district,
        'neighborhood': _neighborhoodCtrl.text.trim().isEmpty ? null : _neighborhoodCtrl.text.trim(),
        'lat': null,
        'lng': null,
        'status': 'pending',
        'isActive': true,
        'usageCount': 0,
        'createdByUid': uid,
        'createdAt': now,
        'updatedAt': now,
      });
      final snap = await ref.get();
      if (!mounted) return;
      Navigator.pop(context, StorePlace.fromDoc(snap));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(left: 20, right: 20, top: 20, bottom: 20 + MediaQuery.of(context).viewInsets.bottom), // LEGACY_EXCEPTION: reason=token_migration owner=codex remove_by=2026-06-30
      child: SingleChildScrollView(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Bu marketi/pazarı öner', style: frDisplay(20, FontWeight.w700)),
          const SizedBox(height: 10),
          TextField(controller: _nameCtrl, decoration: const InputDecoration(labelText: 'Ad')),
          const SizedBox(height: 8),
          TextField(controller: _cityCtrl, decoration: const InputDecoration(labelText: 'İl')),
          const SizedBox(height: 8),
          TextField(controller: _districtCtrl, decoration: const InputDecoration(labelText: 'İlçe')),
          const SizedBox(height: 8),
          TextField(controller: _neighborhoodCtrl, decoration: const InputDecoration(labelText: 'Mahalle (opsiyonel)')),
          const SizedBox(height: 12),
          FRCta(label: _saving ? 'Kaydediliyor…' : 'Öneriyi gönder', icon: Icons.add_business_rounded, onTap: _saving ? null : _save),
        ]),
      ),
    );
  }
}

class _IntroBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18), // LEGACY_EXCEPTION: reason=token_migration owner=codex remove_by=2026-06-30
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [FR.surfaceHi, FR.surfaceLo], begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: FRRad.all(22),
        border: Border.all(color: FR.goldDeep.withOpacity(.3)),
      ),
      child: Row(children: [
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
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('RADAR EKOSİSTEMİ', style: frOverline()),
            const SizedBox(height: 4),
            Text('Her paylaşım topluluğu güçlendirir', style: frText(14, FontWeight.w800, height: 1.3)),
            const SizedBox(height: 2),
            Text('Onaylı katkı başına +10 PT', style: frText(11.5, FontWeight.w600, color: FR.ink3)),
          ]),
        ),
      ]),
    );
  }
}

class _GuideStrip extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14), // LEGACY_EXCEPTION: reason=token_migration owner=codex remove_by=2026-06-30
      decoration: BoxDecoration(color: FR.surfaceLo, borderRadius: FRRad.all(FRRad.m), border: Border.all(color: FR.hairline)),
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
          Expanded(child: Text(text, style: frText(11.5, FontWeight.w600, color: FR.ink3, height: 1.45))),
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
        .where((p) => _q.isEmpty || p.name.toLowerCase().contains(_q.toLowerCase()) || p.brand.toLowerCase().contains(_q.toLowerCase()))
        .toList();

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: .8,
      maxChildSize: .9,
      builder: (ctx, scrollCtrl) => Container(
        decoration: BoxDecoration(color: FR.bg, borderRadius: const BorderRadius.vertical(top: Radius.circular(24))),
        child: Column(children: [
          const SizedBox(height: 10),
          Container(width: 46, height: 4, decoration: BoxDecoration(color: FR.hairline, borderRadius: FRRad.all(99))),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 6), // LEGACY_EXCEPTION: reason=token_migration owner=codex remove_by=2026-06-30
            child: Row(children: [
              Expanded(child: Text('Ürün seç', style: frDisplay(22, FontWeight.w700))),
              InkWell(
                onTap: () => Navigator.pop(context),
                borderRadius: FRRad.all(999),
                child: Padding(
                  padding: const EdgeInsets.all(6), // LEGACY_EXCEPTION: reason=token_migration owner=codex remove_by=2026-06-30
                  child: Icon(Icons.close_rounded, color: FR.ink2),
                ),
              ),
            ]),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 6, 20, 10), // LEGACY_EXCEPTION: reason=token_migration owner=codex remove_by=2026-06-30
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14), // LEGACY_EXCEPTION: reason=token_migration owner=codex remove_by=2026-06-30
              height: 48,
              decoration: frSurface(radius: FRRad.m),
              child: Row(children: [
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
                      hintStyle: frText(13, FontWeight.w600, color: FR.ink3),
                    ),
                  ),
                ),
              ]),
            ),
          ),
          Expanded(
            child: ListView.separated(
              controller: scrollCtrl,
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 30), // LEGACY_EXCEPTION: reason=token_migration owner=codex remove_by=2026-06-30
              itemCount: items.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (_, i) {
                final p = items[i];
                return InkWell(
                  onTap: () => Navigator.pop(context, p),
                  borderRadius: FRRad.all(FRRad.m),
                  child: Container(
                    padding: const EdgeInsets.all(12), // LEGACY_EXCEPTION: reason=token_migration owner=codex remove_by=2026-06-30
                    decoration: frSurface(radius: FRRad.m),
                    child: Row(children: [
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
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(p.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: frText(13.5, FontWeight.w800)),
                          Text('${p.brand} · ${p.unit}', style: frText(11.5, FontWeight.w600, color: FR.ink3)),
                        ]),
                      ),
                    ]),
                  ),
                );
              },
            ),
          ),
        ]),
      ),
    );
  }
}
