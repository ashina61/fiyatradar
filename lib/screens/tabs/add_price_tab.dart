import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
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
  bool _resolvingLocation = false;
  double? _activeLat;
  double? _activeLng;

  @override
  void dispose() {
    _priceCtrl.dispose();
    _noteCtrl.dispose();
    _storeQueryCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit(AppState state) async {
    final pid = _selectedProduct?.id;
    final place = _selectedPlace;
    final price = double.tryParse(_priceCtrl.text.replaceAll(',', '.'));
    if (pid == null || place == null || price == null || price <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ürün, kaynak ve geçerli bir fiyat gir.')),
      );
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
        city: place.city,
        district: place.district,
        sourceType: _sourceType,
        chainId: place.chainId,
        chainName: place.chainName,
        lat: place.lat ?? _activeLat,
        lng: place.lng ?? _activeLng,
      );
      if (!mounted) return;
      _priceCtrl.clear();
      _noteCtrl.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Fiyatı paylaştın · +10 PT · Topluluk doğrulayacak')),
      );
    } on StateError catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
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
    final needsRegion = _sourceType != PriceSourceType.online;
    final hasRegion = _hasActiveRegion(state);
    final query = (needsRegion && !hasRegion) ? null : _buildPlaceQuery(state);

    return SafeArea(
      bottom: false,
      child: Column(
        children: [
          const Padding(
            padding: EdgeInsetsDirectional.fromSTEB(FRSpace.xl, 14, FRSpace.xl, 0),
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
                frScrollPaddingWithFooter(context, footerHeight: 104),
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
                if (needsRegion && !hasRegion)
                  _buildRegionRequiredState(state)
                else if (query != null)
                  StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                    stream: query.snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return Text('Marketler yükleniyor…',
                            style: frText(12, FontWeight.w600, color: FR.ink3));
                      }
                      final docs = snapshot.data?.docs ?? const [];
                      final places = docs
                          .map(StorePlace.fromDoc)
                          .where((place) => _allowPlaceForCurrentUser(state, place, docs))
                          .toList();
                      final search = _storeQueryCtrl.text.trim();
                      if (places.isEmpty) {
                        return _buildEmptyStateForPlaces(state, search: search);
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
                              padding:
                                  const EdgeInsetsDirectional.fromSTEB(14, 10, 14, 10),
                              decoration: BoxDecoration(
                                color: selected ? FR.gold : FR.surface,
                                borderRadius: FRRad.all(999),
                                border:
                                    Border.all(color: selected ? FR.gold : FR.hairline),
                              ),
                              child: Text(
                                place.displayName,
                                style: frText(12, FontWeight.w800,
                                    color: selected ? FR.onGold : FR.ink),
                              ),
                            ),
                          );
                        }).toList(),
                      );
                    },
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

  Query<Map<String, dynamic>> _buildPlaceQuery(AppState state) {
    final coll = FirebaseService.instance.storePlaces;
    var q = coll
        .where('isActive', isEqualTo: true)
        .where('status', whereIn: ['verified', 'trusted', 'pending']);
    switch (_sourceType) {
      case PriceSourceType.physical:
        q = q.where('type', whereIn: ['chain_market', 'local_market']);
        q = q
            .where('city', isEqualTo: (state.cityName ?? '').trim())
            .where('district', isEqualTo: (state.districtName ?? '').trim());
        break;
      case PriceSourceType.online:
        q = q.where('type', isEqualTo: 'online_market');
        break;
      case PriceSourceType.bazaar:
        q = q.where('type', isEqualTo: 'bazaar');
        q = q
            .where('city', isEqualTo: (state.cityName ?? '').trim())
            .where('district', isEqualTo: (state.districtName ?? '').trim());
        break;
    }
    final search = _storeQueryCtrl.text.trim().toLowerCase();
    if (search.isNotEmpty) {
      q = q
          .orderBy('normalizedName')
          .startAt([search]).endAt(['$search\uf8ff']).limit(_kStoreResultLimit);
      return q;
    }
    return q.orderBy('usageCount', descending: true).limit(_kStoreResultLimit);
  }

  Widget _sourceChip(String label, PriceSourceType type) {
    final selected = _sourceType == type;
    return InkWell(
      onTap: () => setState(() {
        _sourceType = type;
        _selectedPlace = null;
      }),
      borderRadius: FRRad.all(999),
      child: Container(
        padding: const EdgeInsetsDirectional.fromSTEB(14, 10, 14, 10),
        decoration: BoxDecoration(
          color: selected ? FR.gold : FR.surface,
          borderRadius: FRRad.all(999),
          border: Border.all(color: selected ? FR.gold : FR.hairline),
        ),
        child: Text(
          label,
          style: frText(12, FontWeight.w800, color: selected ? FR.onGold : FR.ink),
        ),
      ),
    );
  }

  Future<void> _submitPendingPlaceRequest(AppState state) async {
    final suggestion = await showModalBottomSheet<_PendingPlaceSuggestion>(
      context: context,
      isScrollControlled: true,
      backgroundColor: FR.bg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _PendingPlaceSheet(
        initialName: _storeQueryCtrl.text.trim(),
        sourceType: _sourceType,
        city: (state.cityName ?? '').trim(),
        district: (state.districtName ?? '').trim(),
      ),
    );
    if (suggestion == null) return;
    final exists = await FirebaseService.instance.storePlaces
        .where('normalizedName', isEqualTo: suggestion.normalizedName)
        .where('city', isEqualTo: suggestion.city)
        .where('district', isEqualTo: suggestion.district)
        .where('type', isEqualTo: suggestion.type)
        .limit(1)
        .get();
    if (exists.docs.isNotEmpty) {
      final place = StorePlace.fromDoc(exists.docs.first);
      if (mounted) {
        setState(() => _selectedPlace = place);
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bu bölgede aynı kayıt zaten mevcut.')),
      );
      return;
    }
    final created = await FirebaseService.instance.storePlaces.add({
      'chainId': null,
      'chainName': null,
      'type': suggestion.type,
      'displayName': suggestion.name,
      'normalizedName': suggestion.normalizedName,
      'city': suggestion.city,
      'district': suggestion.district,
      'neighborhood': suggestion.neighborhood,
      'lat': suggestion.lat,
      'lng': suggestion.lng,
      'status': 'pending',
      'isActive': true,
      'usageCount': 0,
      'createdByUid': state.user?.uid,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
    setState(() {
      _selectedPlace = StorePlace(
        id: created.id,
        type: storePlaceTypeFromString(suggestion.type),
        displayName: suggestion.name,
        normalizedName: suggestion.normalizedName,
        city: suggestion.city,
        district: suggestion.district,
        neighborhood: suggestion.neighborhood,
        lat: suggestion.lat,
        lng: suggestion.lng,
        status: 'pending',
        isActive: true,
      );
      _activeLat = suggestion.lat ?? _activeLat;
      _activeLng = suggestion.lng ?? _activeLng;
    });
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Market/pazar önerisi eklendi ve seçildi.')),
    );
  }

  bool _hasActiveRegion(AppState state) =>
      (state.cityName ?? '').trim().isNotEmpty &&
      (state.districtName ?? '').trim().isNotEmpty;

  bool _allowPlaceForCurrentUser(
    AppState state,
    StorePlace place,
    List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
  ) {
    if (place.status != 'pending') return true;
    final raw = docs.firstWhere((d) => d.id == place.id).data();
    final createdByUid = (raw['createdByUid'] as String?) ?? '';
    final currentUid = state.user?.uid ?? '';
    return currentUid.isNotEmpty && createdByUid == currentUid;
  }

  Widget _buildRegionRequiredState(AppState state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Fiziksel/pazar fiyatı eklemek için bölge seçmelisin.',
            style: frText(12, FontWeight.w700, color: FR.ink3)),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            FRCta(
              label: _resolvingLocation ? 'Konum alınıyor…' : 'Konumumu kullan',
              icon: Icons.my_location_rounded,
              onTap: _resolvingLocation ? null : () => _resolveLocationAndRegion(state),
            ),
            FRCta(
              label: 'İl / ilçe seç',
              icon: Icons.map_outlined,
              onTap: () => _showManualRegionPicker(state),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildEmptyStateForPlaces(AppState state, {required String search}) {
    final hasSearch = search.isNotEmpty;
    final text = hasSearch
        ? 'Arama ile eşleşen kayıt yok.'
        : 'Bu bölgede kayıtlı market/pazar yok.';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(text, style: frText(12, FontWeight.w600, color: FR.ink3)),
        const SizedBox(height: 10),
        FRCta(
          label: 'Bu marketi/pazarı öner',
          icon: Icons.add_business_rounded,
          onTap: _submitting ? null : () => _submitPendingPlaceRequest(state),
        ),
      ],
    );
  }

  Future<void> _resolveLocationAndRegion(AppState state) async {
    setState(() => _resolvingLocation = true);
    try {
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.deniedForever ||
          permission == LocationPermission.denied) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Konum izni verilmedi. İl/ilçe alanını manuel doldur.')),
        );
        await _showManualRegionPicker(state);
        return;
      }
      final pos = await Geolocator.getCurrentPosition();
      _activeLat = pos.latitude;
      _activeLng = pos.longitude;
      String? city;
      String? district;
      try {
        final placemarks =
            await placemarkFromCoordinates(pos.latitude, pos.longitude);
        if (placemarks.isNotEmpty) {
          final p = placemarks.first;
          city = (p.administrativeArea ?? p.locality ?? '').trim();
          district = (p.subAdministrativeArea ?? p.subLocality ?? '').trim();
        }
      } catch (_) {
        // Falls back to manual region picker below.
      }
      if ((city ?? '').isEmpty || (district ?? '').isEmpty) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Bölge otomatik çözülemedi. İl/ilçe seçmelisin.')),
        );
        await _showManualRegionPicker(state);
        return;
      }
      await state.updateRegionSettings(cityName: city!, districtName: district);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Bölge güncellendi: $city / $district')),
      );
    } finally {
      if (mounted) setState(() => _resolvingLocation = false);
    }
  }

  Future<void> _showManualRegionPicker(AppState state) async {
    final picked = await showModalBottomSheet<({String city, String district})>(
      context: context,
      isScrollControlled: true,
      backgroundColor: FR.bg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _ManualRegionSheet(
        city: (state.cityName ?? '').trim(),
        district: (state.districtName ?? '').trim(),
      ),
    );
    if (picked == null) return;
    await state.updateRegionSettings(cityName: picked.city, districtName: picked.district);
  }
}

class _PendingPlaceSuggestion {
  final String name;
  final String normalizedName;
  final String type;
  final String city;
  final String district;
  final String? neighborhood;
  final double? lat;
  final double? lng;

  const _PendingPlaceSuggestion({
    required this.name,
    required this.normalizedName,
    required this.type,
    required this.city,
    required this.district,
    this.neighborhood,
    this.lat,
    this.lng,
  });
}

class _ManualRegionSheet extends StatefulWidget {
  const _ManualRegionSheet({required this.city, required this.district});
  final String city;
  final String district;

  @override
  State<_ManualRegionSheet> createState() => _ManualRegionSheetState();
}

class _ManualRegionSheetState extends State<_ManualRegionSheet> {
  late final TextEditingController _cityCtrl;
  late final TextEditingController _districtCtrl;

  @override
  void initState() {
    super.initState();
    _cityCtrl = TextEditingController(text: widget.city);
    _districtCtrl = TextEditingController(text: widget.district);
  }

  @override
  void dispose() {
    _cityCtrl.dispose();
    _districtCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsetsDirectional.fromSTEB(
        FRSpace.xl,
        18,
        FRSpace.xl,
        bottom + FRSpace.xl,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _cityCtrl,
            decoration: const InputDecoration(labelText: 'İl'),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _districtCtrl,
            decoration: const InputDecoration(labelText: 'İlçe'),
          ),
          const SizedBox(height: 12),
          FRCta(
            label: 'Bölgeyi kaydet',
            icon: Icons.check_rounded,
            onTap: () {
              final city = _cityCtrl.text.trim();
              final district = _districtCtrl.text.trim();
              if (city.isEmpty || district.isEmpty) return;
              Navigator.pop(context, (city: city, district: district));
            },
          ),
        ],
      ),
    );
  }
}

class _PendingPlaceSheet extends StatefulWidget {
  const _PendingPlaceSheet({
    required this.initialName,
    required this.sourceType,
    required this.city,
    required this.district,
  });
  final String initialName;
  final PriceSourceType sourceType;
  final String city;
  final String district;

  @override
  State<_PendingPlaceSheet> createState() => _PendingPlaceSheetState();
}

class _PendingPlaceSheetState extends State<_PendingPlaceSheet> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _cityCtrl;
  late final TextEditingController _districtCtrl;
  final TextEditingController _neighborhoodCtrl = TextEditingController();
  double? _lat;
  double? _lng;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.initialName);
    _cityCtrl = TextEditingController(text: widget.city);
    _districtCtrl = TextEditingController(text: widget.district);
    _hydrateLocation();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _cityCtrl.dispose();
    _districtCtrl.dispose();
    _neighborhoodCtrl.dispose();
    super.dispose();
  }

  Future<void> _hydrateLocation() async {
    try {
      final permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return;
      }
      final p = await Geolocator.getCurrentPosition();
      if (!mounted) return;
      setState(() {
        _lat = p.latitude;
        _lng = p.longitude;
      });
    } catch (_) {
      // Keep lat/lng optional.
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    final type = widget.sourceType == PriceSourceType.online
        ? 'online_market'
        : (widget.sourceType == PriceSourceType.bazaar ? 'bazaar' : 'local_market');
    return Padding(
      padding: EdgeInsetsDirectional.fromSTEB(
        FRSpace.xl,
        18,
        FRSpace.xl,
        bottom + FRSpace.xl,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _nameCtrl,
              decoration: const InputDecoration(labelText: 'Ad'),
            ),
            const SizedBox(height: 10),
            TextField(
              readOnly: true,
              enabled: false,
              decoration: InputDecoration(labelText: 'Kaynak türü', hintText: type),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _cityCtrl,
              decoration: const InputDecoration(labelText: 'İl'),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _districtCtrl,
              decoration: const InputDecoration(labelText: 'İlçe'),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _neighborhoodCtrl,
              decoration: const InputDecoration(labelText: 'Mahalle (opsiyonel)'),
            ),
            const SizedBox(height: 12),
            FRCta(
              label: 'Öneriyi gönder',
              icon: Icons.add_rounded,
              onTap: () {
                final name = _nameCtrl.text.trim();
                final city = _cityCtrl.text.trim();
                final district = _districtCtrl.text.trim();
                if (name.isEmpty || city.isEmpty || district.isEmpty) return;
                final normalized = name.toLowerCase().replaceAll(RegExp(r'\s+'), ' ').trim();
                Navigator.pop(
                  context,
                  _PendingPlaceSuggestion(
                    name: name,
                    normalizedName: normalized,
                    type: type,
                    city: city,
                    district: district,
                    neighborhood: _neighborhoodCtrl.text.trim().isEmpty
                        ? null
                        : _neighborhoodCtrl.text.trim(),
                    lat: _lat,
                    lng: _lng,
                  ),
                );
              },
            ),
          ],
        ),
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
