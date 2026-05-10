import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';

import '../../models/price_v1.dart';
import '../../models/product.dart';
import '../../models/turkey_locations.dart';
import '../../services/firebase_service.dart';
import '../../state/app_state.dart';
import '../../ui/components.dart';
import '../../ui/tokens.dart';
import '../widgets/region_picker_sheet.dart';

class AddPriceTab extends StatefulWidget {
  const AddPriceTab({super.key});

  @override
  State<AddPriceTab> createState() => _AddPriceTabState();
}

class _AddPriceTabState extends State<AddPriceTab> {
  static const _kStoreResultLimit = 30;
  static const double _kPriceWarnLow = 0.5;
  // 5000 yerine 50000 — lüks et, kuruyemiş, alkollü içecek vb. uç ürünler
  // için bile makul. Üst limit hâlâ "uyarı modal", hard reject değil.
  static const double _kPriceWarnHigh = 50000.0;
  Product? _selectedProduct;
  StorePlace? _selectedPlace;
  // Source type is a top-level choice — physical / bazaar / online. Online
  // entries skip the city+district requirement (they're nationwide) and
  // pull from `online_market` storeplaces only.
  PriceSourceType _sourceType = PriceSourceType.physical;
  final _priceCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();
  final _storeQueryCtrl = TextEditingController();
  // Free-text market fallback — eğer kullanıcı listede market bulamazsa
  // raporu yine de gönderebilsin. Spec "şube zorunlu değil" diyor.
  String? _freeTextStoreName;
  String? _freeTextChainId;
  bool _submitting = false;
  bool _locating = false;
  bool _showOptional = false;
  double? _regionLat;
  double? _regionLng;
  double? _gpsAccuracyMeters;
  // Opsiyonel rafta-fotoğraf akışı.
  Uint8List? _proofPhotoBytes;
  String? _proofPhotoContentType;
  bool _uploadingPhoto = false;
  bool _presetConsumed = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_presetConsumed) return;
    _presetConsumed = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final state = AppStateScope.read(context);
      final preset = state.consumeAddPricePreset();
      Product? product;
      if (preset.productId != null) {
        product = state.findById(preset.productId!);
      }
      final presetChainName = (preset.chainName ?? '').trim();
      if (product == null && presetChainName.isEmpty) return;
      setState(() {
        if (product != null) _selectedProduct = product;
        if (presetChainName.isNotEmpty) _storeQueryCtrl.text = presetChainName;
      });
    });
  }

  @override
  void dispose() {
    _priceCtrl.dispose();
    _noteCtrl.dispose();
    _storeQueryCtrl.dispose();
    super.dispose();
  }

  /// "1.234,56" / "1234,56" / "1234.56" / "1234" formlarını güvenli
  /// şekilde double'a çevirir. Bin ayırıcı noktasıyla yanlış parse riskini
  /// kapatır (önceki implementation `replaceAll(',', '.')` ile "1.234,56"'yı
  /// 1.234'e indiriyordu).
  static double? _parseTrPrice(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return null;
    final lastComma = trimmed.lastIndexOf(',');
    final lastDot = trimmed.lastIndexOf('.');
    String normalized;
    if (lastComma == -1 && lastDot == -1) {
      normalized = trimmed;
    } else if (lastComma > lastDot) {
      // TR locale: virgül ondalık, nokta bin ayırıcı.
      normalized = trimmed.replaceAll('.', '').replaceAll(',', '.');
    } else {
      // Nokta ondalık, virgül bin ayırıcı.
      normalized = trimmed.replaceAll(',', '');
    }
    return double.tryParse(normalized);
  }

  bool get _isOnlineSource => _sourceType == PriceSourceType.online;

  Future<void> _submit(AppState state) async {
    final pid = _selectedProduct?.id;
    final place = _selectedPlace;
    final price = _parseTrPrice(_priceCtrl.text);
    final city = (state.cityName ?? '').trim();
    final district = (state.districtName ?? '').trim();
    final freeText = (_freeTextStoreName ?? '').trim();
    // Online entries don't need region — we send a canonical
    // "Türkiye / Online" marker so the report still satisfies the
    // priceReports schema while the home feed treats it as nationwide.
    final isOnline = _isOnlineSource;
    final effectiveCity = isOnline ? 'Türkiye' : city;
    final effectiveDistrict = isOnline ? 'Online' : district;

    if (pid == null) {
      _snack('Önce ürün seç.');
      return;
    }
    if (price == null || price <= 0) {
      _snack('Geçerli bir fiyat gir.');
      return;
    }
    // Şube seçimi opsiyonel — kullanıcı liste yerine free-text market adı
    // girmiş de olabilir. En azından chain adı (free-text) ya da bir place
    // referansı olmalı; ikisi de yoksa zincir ismi belirsiz kalır.
    if (place == null && freeText.isEmpty) {
      _snack(isOnline
          ? 'Online marketi seç ya da ismini yaz (örn. Migros Sanal Market).'
          : 'Marketi seç ya da listede yoksa ismini yaz.');
      return;
    }
    if (!isOnline && (city.isEmpty || district.isEmpty)) {
      _snack('Bölgesel fiyat için il ve ilçe seç.');
      return;
    }

    if (price < _kPriceWarnLow || price > _kPriceWarnHigh) {
      final go = await showDialog<bool>(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Bu fiyat normal aralığın dışında'),
          content: Text(
            '₺${price.toStringAsFixed(2)} biraz alışılmadık görünüyor. '
            'Yine de göndermek istiyor musun?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Düzenle'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Yine de gönder'),
            ),
          ],
        ),
      );
      if (go != true) return;
    }

    setState(() => _submitting = true);
    try {
      // Mevcut place varsa konum-uyum mesafesi hesaplanır; free-text market
      // durumunda mesafe null kalır → sourceType = manualRegional.
      double? distanceToBranchMeters;
      if (place != null &&
          _regionLat != null &&
          _regionLng != null &&
          place.lat != null &&
          place.lng != null) {
        distanceToBranchMeters = Geolocator.distanceBetween(
          _regionLat!,
          _regionLng!,
          place.lat!,
          place.lng!,
        );
      }

      // Opsiyonel fotoğraf upload'ı submit'ten ÖNCE yap; URL'i raporla
      // birlikte aynı transaction'a yolla. Yükleme başarısızsa rapor yine
      // de gönderilebilsin diye exception swallow ediyoruz, sadece kullanıcıyı
      // uyarıyoruz.
      String? proofUrl;
      if (_proofPhotoBytes != null) {
        setState(() => _uploadingPhoto = true);
        try {
          final uid = state.user?.uid;
          if (uid == null || uid.isEmpty) {
            throw StateError('Fotoğraf yüklemek için giriş gerekiyor.');
          }
          final res = await FirebaseService.instance.uploadPriceProofImage(
            uid: uid,
            bytes: _proofPhotoBytes!,
            contentType: _proofPhotoContentType,
          );
          proofUrl = res.url;
        } catch (e) {
          _snack('Fotoğraf yüklenemedi, fiyat fotoğrafsız gönderiliyor: $e');
          proofUrl = null;
        } finally {
          if (mounted) setState(() => _uploadingPhoto = false);
        }
      }

      final storeDisplay = place?.displayName ?? freeText;
      final chainId = place?.chainId ?? _freeTextChainId ?? place?.displayName ?? freeText;
      final chainName = place?.chainName ??
          place?.displayName ??
          freeText;

      final result = await state.addRegionalPrice(
        productId: pid,
        store: storeDisplay,
        price: price,
        note: _noteCtrl.text.trim(),
        placeId: place?.id,
        city: effectiveCity,
        district: effectiveDistrict,
        chainId: chainId,
        chainName: chainName,
        sourceType: _sourceType,
        proofImageUrl: proofUrl,
        lat: isOnline ? null : _regionLat,
        lng: isOnline ? null : _regionLng,
        distanceToBranchMeters: isOnline ? null : distanceToBranchMeters,
        gpsAccuracyMeters: isOnline ? null : _gpsAccuracyMeters,
      );
      if (!mounted) return;
      _priceCtrl.clear();
      _noteCtrl.clear();
      if (result.duplicate != null) {
        final confirm = await showDialog<bool>(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('Bu fiyat zaten bildirildi'),
            content: const Text(
              'Bu fiyat bugün bu bölgede zaten bildirilmiş. Sen de gördüysen doğrulama olarak ekleyelim mi?',
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Vazgeç')),
              TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Evet, ben de gördüm')),
            ],
          ),
        );
        if (confirm == true) {
          await state.verifyRegionalPriceSeen(
            productId: pid,
            chainId: chainId,
            price: price,
            city: effectiveCity,
            district: effectiveDistrict,
          );
          if (!mounted) return;
          _snack('Doğrulaman kaydedildi.');
        }
      } else {
        final hasProofPhoto = (proofUrl ?? '').isNotEmpty;
        _snack(
          hasProofPhoto
              ? 'Fotoğraflı fiyat admin kontrolüne gönderildi; onay sonrası yayına alınacak.'
              : isOnline
                  ? 'Online fiyat eklendi · $chainName · ${result.sourceLabel}'
                  : 'Fiyat eklendi · '
                      '$chainName / $district bölgesine işlendi · '
                      '${result.sourceLabel}',
        );
        if (mounted) {
          setState(() {
            _selectedProduct = null;
            _proofPhotoBytes = null;
            _proofPhotoContentType = null;
            _priceCtrl.clear();
            _noteCtrl.clear();
          });
          // If the basket "fill missing for chain X" CTA queued more
          // products, drain the next one and keep the chain pre-selected
          // so the user can stay in flow.
          _consumeNextQueuedProduct(state);
        }
      }
    } catch (e) {
      if (!mounted) return;
      _snack('Fiyat gönderilemedi: $e');
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Future<void> _pickProofPhoto({required bool fromCamera}) async {
    if (_uploadingPhoto || _submitting) return;
    final picker = ImagePicker();
    try {
      final picked = await picker.pickImage(
        source: fromCamera ? ImageSource.camera : ImageSource.gallery,
        imageQuality: 80,
        maxWidth: 1600,
      );
      if (picked == null) return;
      final bytes = await picked.readAsBytes();
      if (!mounted) return;
      setState(() {
        _proofPhotoBytes = bytes;
        _proofPhotoContentType = picked.mimeType;
      });
    } catch (e) {
      _snack('Fotoğraf seçilemedi: $e');
    }
  }

  void _clearProofPhoto() {
    setState(() {
      _proofPhotoBytes = null;
      _proofPhotoContentType = null;
    });
  }

  void _consumeNextQueuedProduct(AppState state) {
    if (state.addPricePresetQueueLength == 0) return;
    final preset = state.consumeAddPricePreset();
    final pid = preset.productId;
    if (pid == null) return;
    final product = state.findById(pid);
    if (product == null) return;
    setState(() {
      _selectedProduct = product;
    });
    final left = preset.remaining;
    if (left > 0) {
      _snack('Kuyrukta $left ürün daha var. Sıradaki: ${product.name}');
    } else {
      _snack('Son ürünü de eklemeye başla: ${product.name}');
    }
  }

  void _snack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  /// Returns a short hint about what's missing for submit, or null when the
  /// form is ready to send.
  String? _submitReadyHint(AppState state) {
    if (_selectedProduct == null) return 'Önce ürünü seç.';
    final price = _parseTrPrice(_priceCtrl.text);
    if (price == null || price <= 0) {
      return 'Geçerli bir fiyat gir.';
    }
    final freeText = (_freeTextStoreName ?? '').trim();
    if (_selectedPlace == null && freeText.isEmpty) {
      return _isOnlineSource
          ? 'Online marketi seç ya da ismini yaz.'
          : 'Marketi seç ya da listede yoksa ismini yaz.';
    }
    if (!_isOnlineSource &&
        ((state.cityName ?? '').trim().isEmpty ||
            (state.districtName ?? '').trim().isEmpty)) {
      return 'İl ve ilçe seç.';
    }
    return null;
  }

  /// "Listede yok, elle gir" akışı için kullanıcının yazdığı market adını
  /// state'e bağlıyoruz. Free-text seçildiğinde mevcut place seçimi temizlenir.
  void _useFreeTextStore(String name) {
    final trimmed = name.trim();
    setState(() {
      _selectedPlace = null;
      _freeTextStoreName = trimmed.isEmpty ? null : trimmed;
      _freeTextChainId = null;
    });
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
    String? resolvedCity;
    String? resolvedDistrict;
    try {
      try {
        var permission = await Geolocator.checkPermission();
        if (permission == LocationPermission.denied) {
          permission = await Geolocator.requestPermission();
        }
        if (permission != LocationPermission.denied &&
            permission != LocationPermission.deniedForever) {
          final pos = await Geolocator.getCurrentPosition();
          _regionLat = pos.latitude;
          _regionLng = pos.longitude;
          _gpsAccuracyMeters = pos.accuracy;
          // Reverse geocode + canonicalise so we can set the region
          // directly without forcing the user through the manual picker.
          try {
            final marks = await placemarkFromCoordinates(
              pos.latitude,
              pos.longitude,
            );
            final mark = marks.isNotEmpty ? marks.first : null;
            final cityRaw = (mark?.administrativeArea ?? mark?.locality ?? '').trim();
            final districtRaw =
                (mark?.subAdministrativeArea ?? mark?.subLocality ?? '').trim();
            final city = TurkeyLocations.canonicalCity(cityRaw);
            if (city != null) {
              final district = TurkeyLocations.canonicalDistrict(city, districtRaw);
              resolvedCity = city;
              resolvedDistrict = district;
            }
          } catch (_) {
            // Reverse geocoding plugin can fail silently on some devices;
            // we'll fall back to the manual picker below.
          }
        }
      } catch (_) {
        // GPS is best-effort; fall through to the manual picker.
      }

      if (resolvedCity != null && resolvedDistrict != null) {
        await state.updateRegionSettings(
          cityName: resolvedCity,
          districtName: resolvedDistrict,
        );
        if (!mounted) return;
        _snack('Bölge ayarlandı: $resolvedCity / $resolvedDistrict');
        return;
      }

      // GPS hit returned a city but not a usable district, or we couldn't
      // resolve it at all → drop into the manual picker so the user can
      // finish the selection.
      await _pickRegionManually(state);
    } finally {
      if (mounted) setState(() => _locating = false);
    }
  }

  Future<void> _pickRegionManually(AppState state) async {
    final result = await showRegionPickerSheet(
      context,
      initialCity: state.cityName,
      initialDistrict: state.districtName,
    );
    if (result == null) return;
    final city = TurkeyLocations.canonicalCity(result.city) ?? result.city;
    final district =
        TurkeyLocations.canonicalDistrict(city, result.district) ?? result.district;
    await state.updateRegionSettings(cityName: city, districtName: district);
    if (!mounted) return;
    _snack('Bölge ayarlandı: $city / $district');
  }

  Query<Map<String, dynamic>> _basePlaceQuery(AppState state, {required bool search}) {
    final coll = FirebaseService.instance.storePlaces;
    final city = (state.cityName ?? '').trim();
    final district = (state.districtName ?? '').trim();

    Query<Map<String, dynamic>> q = coll.where('isActive', isEqualTo: true);

    switch (_sourceType) {
      case PriceSourceType.bazaar:
        q = q.where('type', isEqualTo: 'bazaar');
        break;
      case PriceSourceType.online:
        // Online markets are nationwide — no city/district filter applies.
        q = q.where('type', isEqualTo: 'online_market');
        break;
      case PriceSourceType.physical:
        q = q.where('type', whereIn: const ['chain_market', 'local_market']);
        break;
    }
    if (_sourceType != PriceSourceType.online) {
      q = q.where('city', isEqualTo: city).where('district', isEqualTo: district);
    }
    q = q.where('status', whereIn: const ['verified', 'trusted']);

    final searchText = _storeQueryCtrl.text.trim().toLowerCase();
    if (search && searchText.isNotEmpty) {
      return q
          .orderBy('normalizedName')
          .startAt([searchText]).endAt(['$searchText\uf8ff']).limit(_kStoreResultLimit);
    }
    return q.orderBy('usageCount', descending: true).limit(_kStoreResultLimit);
  }

  Stream<List<StorePlace>> _placeStream(AppState state) async* {
    final isOnline = _sourceType == PriceSourceType.online;
    if (!isOnline &&
        ((state.cityName ?? '').trim().isEmpty ||
            (state.districtName ?? '').trim().isEmpty)) {
      yield const <StorePlace>[];
      return;
    }

    final ownUid = state.user?.uid;
    final hasSearch = _storeQueryCtrl.text.trim().isNotEmpty;
    final all = <String, StorePlace>{};
    try {
      final normalQuery = _basePlaceQuery(state, search: hasSearch);
      final normalSnap = await normalQuery.get();
      for (final d in normalSnap.docs) {
        all[d.id] = StorePlace.fromDoc(d);
      }
    } catch (e) {
      // Surface via Flutter's debug log so it shows up in `flutter logs`
      // (and gets stripped from release builds), instead of writing to
      // stdout. We still try the user's own pending places below so the
      // picker isn't completely empty if a Firestore index is missing.
      debugPrint('add_price: place query failed → $e');
    }

    if (ownUid != null && ownUid.isNotEmpty) {
      try {
        Query<Map<String, dynamic>> ownPendingQ = FirebaseService.instance.storePlaces
            .where('isActive', isEqualTo: true)
            .where('createdByUid', isEqualTo: ownUid)
            .where('status', isEqualTo: 'pending');
        if (!isOnline) {
          final city = (state.cityName ?? '').trim();
          final district = (state.districtName ?? '').trim();
          ownPendingQ = ownPendingQ
              .where('city', isEqualTo: city)
              .where('district', isEqualTo: district);
        }
        final ownPendingSnap =
            await ownPendingQ.limit(_kStoreResultLimit).get();
        for (final d in ownPendingSnap.docs) {
          final place = StorePlace.fromDoc(d);
          if (_sourceType == PriceSourceType.physical &&
              !(place.type == StorePlaceType.chainMarket || place.type == StorePlaceType.localMarket)) {
            continue;
          }
          if (_sourceType == PriceSourceType.bazaar && place.type != StorePlaceType.bazaar) {
            continue;
          }
          if (isOnline && place.type != StorePlaceType.onlineMarket) {
            continue;
          }
          all[d.id] = place;
        }
      } catch (_) {
        // Pending lookup is best-effort; fall through.
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
    final regionMissing = city.isEmpty || district.isEmpty;
    final priceVal = _parseTrPrice(_priceCtrl.text);
    final priceValid = priceVal != null && priceVal > 0;

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
                _ProgressStrip(
                  productDone: _selectedProduct != null,
                  priceDone: priceValid,
                  storeDone:
                      _selectedPlace != null || (_freeTextStoreName ?? '').trim().isNotEmpty,
                  regionDone: _isOnlineSource ||
                      (city.isNotEmpty && district.isNotEmpty),
                  onlineMode: _isOnlineSource,
                ),
                const SizedBox(height: 18),

                // 1) Ürün — "Ne gördün?"
                _step(1, 'Ne gördün?', completed: _selectedProduct != null),
                InkWell(
                  onTap: () => _pickProduct(state),
                  borderRadius: FRRad.all(FRRad.m),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: FR.surface,
                      borderRadius: FRRad.all(FRRad.m),
                      border: Border.all(
                        color: _selectedProduct != null
                            ? FR.gold.withOpacity(.55)
                            : FR.hairline,
                        width: _selectedProduct != null ? 1.4 : 1.0,
                      ),
                      boxShadow:
                          _selectedProduct != null ? frGoldGlow(opacity: .12) : null,
                    ),
                    child: Row(children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: _selectedProduct != null
                                ? [FR.gold.withOpacity(.18), FR.surfaceLo]
                                : [FR.bgElev, FR.bgElev],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: FRRad.all(12),
                          border: Border.all(
                            color: _selectedProduct != null
                                ? FR.gold.withOpacity(.45)
                                : FR.hairline,
                          ),
                        ),
                        alignment: Alignment.center,
                        child: Text(_selectedProduct?.emoji ?? '🔎', style: const TextStyle(fontSize: 22)),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _selectedProduct == null
                            ? Text('Onaylı ürünlerde ara…', style: frText(13, FontWeight.w600, color: FR.ink3))
                            : Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                Text(_selectedProduct!.name,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: frText(14, FontWeight.w800)),
                                const SizedBox(height: 2),
                                Text('${_selectedProduct!.brand} · ${_selectedProduct!.unit}',
                                    style: frText(11.5, FontWeight.w600, color: FR.ink3)),
                              ]),
                      ),
                      Icon(
                        _selectedProduct != null
                            ? Icons.swap_horiz_rounded
                            : Icons.chevron_right_rounded,
                        color: _selectedProduct != null ? FR.gold : FR.ink3,
                      ),
                    ]),
                  ),
                ),
                const SizedBox(height: 22),

                // 2) Fiyat — "Fiyat kaç TL?"
                _step(2, 'Fiyat kaç TL?', completed: priceValid),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  decoration: BoxDecoration(
                    color: FR.surface,
                    borderRadius: FRRad.all(FRRad.m),
                    border: Border.all(
                      color: priceValid ? FR.gold.withOpacity(.55) : FR.hairline,
                      width: priceValid ? 1.4 : 1.0,
                    ),
                    boxShadow: priceValid ? frGoldGlow(opacity: .12) : null,
                  ),
                  child: Row(children: [
                    Text('₺', style: frDisplay(26, FontWeight.w700, color: FR.gold)),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        controller: _priceCtrl,
                        onChanged: (_) => setState(() {}),
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        style: frPrice(30),
                        cursorColor: FR.gold,
                        decoration: InputDecoration(
                          border: InputBorder.none,
                          hintText: '0,00',
                          hintStyle: frPrice(30, color: FR.ink3),
                          isCollapsed: true,
                          contentPadding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                      ),
                    ),
                    if ((_selectedProduct?.unit ?? '').isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: FR.bgElev,
                          borderRadius: FRRad.all(999),
                          border: Border.all(color: FR.hairline),
                        ),
                        child: Text(
                          _selectedProduct!.unit,
                          style: frText(11, FontWeight.w800, color: FR.ink2),
                        ),
                      ),
                  ]),
                ),
                const SizedBox(height: 22),

                // 3) Market — "Hangi markette gördün?"
                _step(3, _isOnlineSource ? 'Hangi online markette?' : 'Hangi markette gördün?',
                    completed: _selectedPlace != null ||
                        (_freeTextStoreName ?? '').trim().isNotEmpty),
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _sourceChip('Market', PriceSourceType.physical),
                      _sourceChip('Online', PriceSourceType.online),
                      _sourceChip('Pazar', PriceSourceType.bazaar),
                    ],
                  ),
                ),
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
                      hintText: _isOnlineSource
                          ? 'Migros Sanal, CarrefourSA Online, Trendyol Yemek…'
                          : 'BİM, A101, ŞOK, Migros…',
                      hintStyle: frText(12.5, FontWeight.w600, color: FR.ink3),
                      prefixIcon: Icon(Icons.search_rounded, color: FR.ink3, size: 18),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                _ChainQuickPickRow(
                  sourceType: _sourceType,
                  selectedChainId: _freeTextChainId,
                  onPick: (id, name) => setState(() {
                    _selectedPlace = null;
                    _freeTextChainId = id;
                    _freeTextStoreName = name;
                    _storeQueryCtrl.text = name;
                  }),
                ),
                const SizedBox(height: 10),
                if (!_isOnlineSource && regionMissing)
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
                          final isPending = place.status == 'pending';
                          return InkWell(
                            onTap: () => setState(() {
                              _selectedPlace = place;
                              _freeTextStoreName = null;
                              _freeTextChainId = null;
                            }),
                            borderRadius: FRRad.all(999),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 150),
                              padding: const EdgeInsetsDirectional.fromSTEB(14, 10, 14, 10),
                              decoration: BoxDecoration(
                                color: selected ? FR.gold : FR.surface,
                                borderRadius: FRRad.all(999),
                                border: Border.all(
                                  color: selected ? FR.gold : FR.hairline,
                                  width: selected ? 1.4 : 1.0,
                                ),
                                boxShadow: selected ? frGoldGlow(opacity: .18) : null,
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (selected) ...[
                                    Icon(Icons.check_rounded,
                                        size: 14, color: FR.onGold),
                                    const SizedBox(width: 6),
                                  ],
                                  Text(place.displayName,
                                      style: frText(12.5, FontWeight.w800,
                                          color: selected ? FR.onGold : FR.ink)),
                                  if (isPending) ...[
                                    const SizedBox(width: 6),
                                    Icon(Icons.schedule_rounded,
                                        size: 11,
                                        color: selected ? FR.onGold : FR.warn),
                                  ],
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                      );
                    },
                  ),
                const SizedBox(height: 8),
                _selectedStoreSummary(),
                const SizedBox(height: 22),

                // 4) Nerede gördün? — region (online prices skip this).
                if (!_isOnlineSource) ...[
                  _step(4, 'Nerede gördün?',
                      completed: city.isNotEmpty && district.isNotEmpty),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text(
                      'Sadece il ve ilçe seviyesinde tutuyoruz.',
                      style: frText(11.5, FontWeight.w600, color: FR.ink3, height: 1.4),
                    ),
                  ),
                  if (city.isNotEmpty && district.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: FR.surface,
                        borderRadius: FRRad.all(FRRad.m),
                        border: Border.all(color: FR.gold.withOpacity(.55), width: 1.4),
                        boxShadow: frGoldGlow(opacity: .12),
                      ),
                      child: Row(children: [
                        Container(
                          width: 40,
                          height: 40,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: FR.gold.withOpacity(.16),
                            borderRadius: FRRad.all(12),
                            border: Border.all(color: FR.gold.withOpacity(.45)),
                          ),
                          child: Icon(Icons.location_on_rounded,
                              color: FR.gold, size: 19),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('$district / $city',
                                  style: frText(13.5, FontWeight.w800)),
                              const SizedBox(height: 2),
                              Row(children: [
                                Icon(
                                  _regionLat != null
                                      ? Icons.gps_fixed_rounded
                                      : Icons.touch_app_outlined,
                                  size: 11,
                                  color: FR.ink3,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  _regionLat != null
                                      ? 'Konumdan algılandı'
                                      : 'Manuel seçildi',
                                  style: frText(10.5, FontWeight.w700,
                                      color: FR.ink3),
                                ),
                              ]),
                            ],
                          ),
                        ),
                        InkWell(
                          onTap: () => _pickRegionManually(state),
                          borderRadius: FRRad.all(999),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 7),
                            decoration: BoxDecoration(
                              color: FR.bgElev,
                              borderRadius: FRRad.all(999),
                              border: Border.all(color: FR.hairline),
                            ),
                            child: Text('Değiştir',
                                style: frText(11.5, FontWeight.w800,
                                    color: FR.gold)),
                          ),
                        ),
                      ]),
                    )
                  else
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: frSurface(radius: FRRad.m),
                      child: Wrap(spacing: 8, runSpacing: 8, children: [
                        FRCta(
                          label: _locating ? 'Konum alınıyor…' : 'Konumla doldur',
                          icon: Icons.my_location_rounded,
                          height: 44,
                          onTap: _locating ? null : () => _useCurrentLocation(state),
                        ),
                        FRCta(
                          label: 'Elle seç',
                          icon: Icons.map_outlined,
                          filled: false,
                          height: 44,
                          onTap: () => _pickRegionManually(state),
                        ),
                      ]),
                    ),
                  const SizedBox(height: 22),
                ],

                // Optional accordion: raf fotoğrafı + not. Source type
                // moved to a top-level visible toggle above.
                _OptionalAccordion(
                  expanded: _showOptional,
                  onToggle: () => setState(() => _showOptional = !_showOptional),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _label('Raf fotoğrafı (opsiyonel — güveni artırır)'),
                      _ProofPhotoPicker(
                        bytes: _proofPhotoBytes,
                        uploading: _uploadingPhoto,
                        onPickCamera: () =>
                            _pickProofPhoto(fromCamera: true),
                        onPickGallery: () =>
                            _pickProofPhoto(fromCamera: false),
                        onClear: _clearProofPhoto,
                      ),
                      const SizedBox(height: 14),
                      _label('Not'),
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
                            hintText: 'Kampanya, raf etiketi, stok bilgisi…',
                            hintStyle: frText(12.5, FontWeight.w600, color: FR.ink3),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          SafeArea(
            top: false,
            bottom: true,
            minimum: EdgeInsets.only(bottom: frStickyFooterBottomPadding(context)), // LEGACY_EXCEPTION: reason=token_migration owner=codex remove_by=2026-06-30
            child: Container(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 10),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [FR.bgElev, FR.bg],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
                border: Border(top: BorderSide(color: FR.hairline)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_submitReadyHint(state) != null) ...[
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
                          Icon(Icons.info_outline_rounded,
                              size: 13, color: FR.ink3),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              _submitReadyHint(state)!,
                              style: frText(11.5, FontWeight.w700,
                                  color: FR.ink3),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  FRCta(
                    label: _submitting ? 'Gönderiliyor…' : 'Fiyatı ekle · +10 PT',
                    icon: Icons.radar_rounded,
                    onTap: _submitting ? null : () => _submit(state),
                  ),
                ],
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
    final isBazaar = _sourceType == PriceSourceType.bazaar;
    final isOnline = _sourceType == PriceSourceType.online;
    final title = isOnline
        ? (hasSearch
            ? 'Arama ile eşleşen online market yok.'
            : 'Henüz kayıtlı online market yok.')
        : isBazaar
            ? (hasSearch
                ? 'Arama ile eşleşen pazar yok.'
                : 'Bu bölgede kayıtlı pazar yok.')
            : (hasSearch
                ? 'Arama ile eşleşen market yok.'
                : 'Bu bölgede kayıtlı market yok.');
    final suggestLabel = isOnline
        ? 'Bu online marketi kaydet'
        : (isBazaar ? 'Bu pazarı kaydet' : 'Bu marketi kaydet');
    final freeTextLabel = hasSearch
        ? 'Bu adı kullan: "${_storeQueryCtrl.text.trim()}"'
        : 'Listede yok — elle yaz';
    return Container(
      padding: const EdgeInsets.all(14), // LEGACY_EXCEPTION: reason=token_migration owner=codex remove_by=2026-06-30
      decoration: frSurface(radius: FRRad.m),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: frText(12.5, FontWeight.w700, color: FR.ink3)),
        const SizedBox(height: 10),
        // Hızlı yol: free-text market adıyla ilerle (place doc oluşturma yok).
        // Spec "şube zorunlu değil" diyor; kullanıcı market önermeye
        // gerek duymadan fiyatı raporlayabilsin.
        FRCta(
          label: freeTextLabel,
          icon: Icons.flash_on_rounded,
          onTap: _submitting
              ? null
              : () {
                  final raw = _storeQueryCtrl.text.trim();
                  if (raw.isEmpty) {
                    _snack('Önce arama kutusuna market adını yaz.');
                    return;
                  }
                  _useFreeTextStore(raw);
                  _snack(
                      'Şimdilik "$raw" adıyla kaydediyoruz. Sonra moderasyon doğrulayacak.');
                },
        ),
        const SizedBox(height: 8),
        // İkinci adım: detaylı "öner" sheet'i, mahalle vs. doldurmak için.
        FRCta(
          label: suggestLabel,
          icon: Icons.add_business_rounded,
          filled: false,
          onTap: _submitting ? null : () => _openSuggestPlaceSheet(state),
        ),
      ]),
    );
  }

  /// Seçili market özet kartı altında küçük bilgi: "free-text" ya da
  /// "kayıtlı yer" — kullanıcı hangi yola gittiğini hep bilsin.
  Widget _selectedStoreSummary() {
    if (_selectedPlace != null) {
      final p = _selectedPlace!;
      return Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: FR.surfaceLo,
          borderRadius: FRRad.all(FRRad.m),
          border: Border.all(color: FR.hairline),
        ),
        child: Row(children: [
          Icon(Icons.storefront_rounded, color: FR.gold, size: 16),
          const SizedBox(width: 8),
          Expanded(
              child: Text('${p.displayName} · seçildi',
                  style: frText(12, FontWeight.w800, color: FR.ink2))),
          InkWell(
            onTap: () => setState(() => _selectedPlace = null),
            child: Icon(Icons.close_rounded, color: FR.ink3, size: 16),
          ),
        ]),
      );
    }
    final freeText = (_freeTextStoreName ?? '').trim();
    if (freeText.isEmpty) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: FR.surfaceLo,
        borderRadius: FRRad.all(FRRad.m),
        border: Border.all(color: FR.warn.withOpacity(.4)),
      ),
      child: Row(children: [
        Icon(Icons.edit_note_rounded, color: FR.warn, size: 16),
        const SizedBox(width: 8),
        Expanded(
          child: Text('"$freeText" — moderasyon onayı bekleyecek.',
              style: frText(11.5, FontWeight.w700, color: FR.ink2)),
        ),
        InkWell(
          onTap: () => setState(() {
            _freeTextStoreName = null;
            _freeTextChainId = null;
          }),
          child: Icon(Icons.close_rounded, color: FR.ink3, size: 16),
        ),
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

  /// Numbered step header for the linear add-price flow. Switches to a gold
  /// check badge when [completed] is true so the user gets a clear premium
  /// progress signal as they fill in each field.
  Widget _step(int n, String text, {bool completed = false}) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Row(children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 26,
            height: 26,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: completed
                    ? [FR.goldHi, FR.goldDeep]
                    : [FR.surfaceHi, FR.surface],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: FRRad.all(999),
              border: Border.all(
                color: completed ? FR.gold : FR.hairline,
              ),
              boxShadow: completed ? frGoldGlow(opacity: .22) : null,
            ),
            child: completed
                ? Icon(Icons.check_rounded, color: FR.onGold, size: 15)
                : Text('$n',
                    style: frText(12, FontWeight.w800, color: FR.ink)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(text,
                style: frText(15, FontWeight.w800,
                    height: 1.2, letter: -0.2)),
          ),
          if (completed)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: FR.good.withOpacity(.14),
                borderRadius: FRRad.all(999),
                border: Border.all(color: FR.good.withOpacity(.35)),
              ),
              child: Text('TAMAM',
                  style: frText(9, FontWeight.w800,
                      color: FR.good, letter: 1.1)),
            ),
        ]),
      );

  Widget _sourceChip(String label, PriceSourceType type) {
    final selected = _sourceType == type;
    return InkWell(
      onTap: () => setState(() {
        _sourceType = type;
        _selectedPlace = null;
        _freeTextStoreName = null;
        _freeTextChainId = null;
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


class _ChainQuickPickRow extends StatelessWidget {
  const _ChainQuickPickRow({
    required this.sourceType,
    required this.selectedChainId,
    required this.onPick,
  });
  final PriceSourceType sourceType;
  final String? selectedChainId;
  final void Function(String id, String name) onPick;

  String get _channelKey => sourceType == PriceSourceType.online ? 'online' : 'physical';

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseService.instance.storeChains
          .orderBy('name')
          .limit(24)
          .snapshots(),
      builder: (context, snap) {
        if (snap.hasError) return const SizedBox.shrink();
        final docs = (snap.data?.docs ?? const <QueryDocumentSnapshot<Map<String, dynamic>>>[])
            .where((d) {
          final m = d.data();
          if (!((m['isActive'] as bool?) ?? true)) return false;
          final supported = m['supportedChannels'];
          if (supported is Map && supported[_channelKey] is bool) {
            return supported[_channelKey] == true;
          }
          if (_channelKey == 'online') {
            return (m['isOnlineEnabled'] as bool?) ??
                (m['supportsOnline'] as bool?) ??
                false;
          }
          return (m['isPhysicalEnabled'] as bool?) ??
              (m['supportsPhysical'] as bool?) ??
              true;
        }).toList(growable: false);
        if (docs.isEmpty) return const SizedBox.shrink();
        return Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final d in docs)
              Builder(builder: (context) {
                final selected = selectedChainId == d.id;
                final name = (d.data()['name'] ?? '').toString();
                return InkWell(
                  onTap: () => onPick(d.id, name),
                  borderRadius: FRRad.all(999),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    padding: const EdgeInsetsDirectional.fromSTEB(12, 8, 12, 8),
                    decoration: BoxDecoration(
                      color: selected ? FR.gold : FR.surface,
                      borderRadius: FRRad.all(999),
                      border: Border.all(color: selected ? FR.gold : FR.hairline),
                      boxShadow: selected ? frGoldGlow(opacity: .14) : null,
                    ),
                    child: Text(
                      name,
                      style: frText(11.5, FontWeight.w800, color: selected ? FR.onGold : FR.ink),
                    ),
                  ),
                );
              }),
          ],
        );
      },
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
  final TextEditingController _neighborhoodCtrl = TextEditingController();
  late String? _city;
  late String? _district;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController();
    _city = TurkeyLocations.canonicalCity(widget.city);
    _district = _city == null
        ? null
        : TurkeyLocations.canonicalDistrict(_city, widget.district);
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
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
    final state = AppStateScope.read(context);
    final uid = state.user?.uid;
    if (uid == null || uid.isEmpty) return;
    final name = _nameCtrl.text.trim().replaceAll(RegExp(r'\s+'), ' ');
    final normalized = _normalize(name);
    final city = _city ?? '';
    final district = _district ?? '';
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
        'sourceType': widget.sourceType == PriceSourceType.online
            ? 'online'
            : widget.sourceType == PriceSourceType.bazaar
                ? 'bazaar'
                : 'physical',
        'channel': widget.sourceType == PriceSourceType.online
            ? 'online'
            : widget.sourceType == PriceSourceType.bazaar
                ? 'bazaar'
                : 'physical',
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

  Future<void> _changeRegion() async {
    final result = await showRegionPickerSheet(
      context,
      initialCity: _city,
      initialDistrict: _district,
    );
    if (result == null) return;
    setState(() {
      _city = result.city;
      _district = result.district;
    });
  }

  @override
  Widget build(BuildContext context) {
    final regionLabel = (_city != null && _district != null)
        ? '$_city / $_district'
        : 'İl ve ilçe seç';
    return Padding(
      padding: EdgeInsets.only(left: 20, right: 20, top: 20, bottom: 20 + MediaQuery.of(context).viewInsets.bottom),
      child: SingleChildScrollView(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Bu marketi/pazarı öner', style: frDisplay(20, FontWeight.w700)),
          const SizedBox(height: 10),
          TextField(controller: _nameCtrl, decoration: const InputDecoration(labelText: 'Ad')),
          const SizedBox(height: 12),
          if (widget.sourceType != PriceSourceType.online) ...[
            InkWell(
              onTap: _changeRegion,
              borderRadius: FRRad.all(FRRad.m),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: FR.bgElev,
                  borderRadius: FRRad.all(FRRad.m),
                  border: Border.all(color: FR.hairline),
                ),
                child: Row(
                  children: [
                    Icon(Icons.place_outlined, size: 18, color: FR.gold),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('İL / İLÇE',
                              style: frOverline(color: FR.ink3, size: 9.5)),
                          const SizedBox(height: 2),
                          Text(regionLabel,
                              style: frText(13.5, FontWeight.w800)),
                        ],
                      ),
                    ),
                    Icon(Icons.keyboard_arrow_right_rounded, color: FR.ink3),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
          ],
          TextField(controller: _neighborhoodCtrl, decoration: const InputDecoration(labelText: 'Mahalle (opsiyonel)')),
          const SizedBox(height: 12),
          FRCta(label: _saving ? 'Kaydediliyor…' : 'Öneriyi gönder', icon: Icons.add_business_rounded, onTap: _saving ? null : _save),
        ]),
      ),
    );
  }
}

class _OptionalAccordion extends StatelessWidget {
  const _OptionalAccordion({
    required this.expanded,
    required this.onToggle,
    required this.child,
  });
  final bool expanded;
  final VoidCallback onToggle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: frSurface(radius: FRRad.m),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: onToggle,
            borderRadius: FRRad.all(FRRad.m),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
              child: Row(
                children: [
                  Icon(Icons.tune_rounded, size: 16, color: FR.ink2),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'İstersen güveni artır (opsiyonel)',
                      style: frText(12.5, FontWeight.w800),
                    ),
                  ),
                  Icon(
                    expanded
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
                    color: FR.ink3,
                  ),
                ],
              ),
            ),
          ),
          if (expanded)
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
              child: child,
            ),
        ],
      ),
    );
  }
}

/// Slim 4-dot progress indicator that replaced the bulky "Radar ekosistemi"
/// banner. Each dot lights up gold as the matching step is filled in so the
/// user gets a visual sense of how close they are to submitting without the
/// previous wall-of-card noise.
class _ProgressStrip extends StatelessWidget {
  const _ProgressStrip({
    required this.productDone,
    required this.priceDone,
    required this.storeDone,
    required this.regionDone,
    required this.onlineMode,
  });
  final bool productDone;
  final bool priceDone;
  final bool storeDone;
  final bool regionDone;
  final bool onlineMode;

  @override
  Widget build(BuildContext context) {
    final steps = <bool>[
      productDone,
      priceDone,
      storeDone,
      if (!onlineMode) regionDone,
    ];
    final filled = steps.where((s) => s).length;
    final total = steps.length;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: FR.surfaceLo,
        borderRadius: FRRad.all(FRRad.m),
        border: Border.all(color: FR.hairline),
      ),
      child: Row(
        children: [
          Icon(Icons.radar_rounded, color: FR.gold, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              filled == total
                  ? 'Hazır — gönderebilirsin · +10 PT'
                  : '${total - filled} adım kaldı · +10 PT',
              style: frText(12.5, FontWeight.w800),
            ),
          ),
          ...List.generate(total, (i) {
            final on = i < filled;
            return Padding(
              padding: const EdgeInsets.only(left: 4),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: on ? FR.gold : FR.hairline,
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
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


class _ProofPhotoPicker extends StatelessWidget {
  const _ProofPhotoPicker({
    required this.bytes,
    required this.uploading,
    required this.onPickCamera,
    required this.onPickGallery,
    required this.onClear,
  });
  final Uint8List? bytes;
  final bool uploading;
  final VoidCallback onPickCamera;
  final VoidCallback onPickGallery;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    if (bytes != null) {
      return Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: FR.surfaceLo,
          borderRadius: FRRad.all(FRRad.m),
          border: Border.all(color: FR.gold.withOpacity(.45)),
        ),
        child: Row(children: [
          ClipRRect(
            borderRadius: FRRad.all(10),
            child: Image.memory(
              bytes!,
              width: 56,
              height: 56,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Fotoğraf hazır',
                    style: frText(12.5, FontWeight.w800, color: FR.ink)),
                const SizedBox(height: 2),
                Text(
                  uploading ? 'Yükleniyor…' : 'Gönderince admin kontrolüne düşecek.',
                  style: frText(11, FontWeight.w600, color: FR.ink3),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: uploading ? null : onClear,
            icon: Icon(Icons.delete_outline_rounded, color: FR.bad, size: 18),
            tooltip: 'Fotoğrafı kaldır',
          ),
        ]),
      );
    }
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        FRCta(
          label: 'Kamera ile çek',
          icon: Icons.photo_camera_rounded,
          height: 42,
          onTap: uploading ? null : onPickCamera,
        ),
        FRCta(
          label: 'Galeriden seç',
          icon: Icons.photo_library_outlined,
          filled: false,
          height: 42,
          onTap: uploading ? null : onPickGallery,
        ),
      ],
    );
  }
}
