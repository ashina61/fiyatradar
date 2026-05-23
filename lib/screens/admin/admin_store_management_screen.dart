import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../models/turkey_locations.dart';
import '../../services/firebase_service.dart';
import '../../state/app_state.dart';
import '../../ui/components.dart';
import '../../ui/tokens.dart';
import '../widgets/region_picker_sheet.dart';
import 'admin_shared_widgets.dart';

class AdminStoreManagementScreen extends StatefulWidget {
  const AdminStoreManagementScreen({
    super.key,
    this.initialTab = 0,
    this.openCreateOnLaunch = false,
  });

  /// Deep-link entry: 0=Zincirler, 1=Fiziksel, 2=Online, 3=Pazarlar,
  /// 4=Bekleyen, 5=Eski. Admin panelinden gelen "şube ekle" gibi kısayollar
  /// uygun sekmeyi açar.
  final int initialTab;

  /// Açılır açılmaz ilgili sekmenin "yeni kayıt" sheet'ini açar.
  /// Mağaza yönetiminin admin panel kısayollarından gelen "Yeni şube"
  /// gibi aksiyonlar için kullanılır.
  final bool openCreateOnLaunch;

  @override
  State<AdminStoreManagementScreen> createState() =>
      _AdminStoreManagementScreenState();
}

class _AdminStoreManagementScreenState
    extends State<AdminStoreManagementScreen> {
  static const _pageSize = 50;
  /// Admin paneli sadece Türkçe — kullanıcı dil değiştirse bile
  /// admin etiketleri hep TR. Bunun için literal liste yeterli.
  ///
  /// Eskiden "Zincirler" ayrı bir sekmeydi; topluluk geri bildirimine göre
  /// "iki ayrı sisteme gerek yok" — zincir master listesi artık "Fiziksel
  /// Mağazalar" sekmesinin başına gömülü olarak yönetiliyor. Online
  /// mağazalar da aynı zincir kataloğunu paylaşıyor.
  static const _tabs = [
    'Fiziksel Mağazalar',
    'Online Mağazalar',
    'Mahalle Pazarları',
    'Onay Bekleyen',
    'Eski Kayıtlar',
  ];

  // Tab indeksleri. "Zincirler" sekmesi kaldırıldı; admin_screen.dart deep
  // linkleri de bu sıraya göre güncellendi.
  static const int _tabPhysical = 0;
  static const int _tabOnline = 1;
  static const int _tabBazaar = 2;
  static const int _tabPending = 3;
  static const int _tabLegacy = 4;

  int _tab = 0;
  final _cityCtrl = TextEditingController();
  final _districtCtrl = TextEditingController();
  final _searchCtrl = TextEditingController();
  String _type = 'all';
  // 'physical' | 'online' | 'bazaar' — hangi liste açıksa o.
  String _placeChannel = 'physical';
  String _status = 'all';
  QueryDocumentSnapshot<Map<String, dynamic>>? _placesLastDoc;
  final List<QueryDocumentSnapshot<Map<String, dynamic>>> _placeDocs = [];
  bool _loadingPlaces = false;
  bool _hasMorePlaces = false;
  LegacyStoreMigrationResult? _legacyMigration;
  QueryDocumentSnapshot<Map<String, dynamic>>? _legacyCursor;
  bool _legacyBusy = false;

  @override
  void initState() {
    super.initState();
    final initial = widget.initialTab.clamp(0, _tabs.length - 1);
    _tab = initial;
    if (initial == _tabPhysical) _placeChannel = 'physical';
    if (initial == _tabOnline) _placeChannel = 'online';
    if (initial == _tabBazaar) _placeChannel = 'bazaar';
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _loadingPlaces) return;
      _loadPlaces(reset: true);
      final openable = initial == _tabPhysical ||
          initial == _tabOnline ||
          initial == _tabBazaar;
      if (widget.openCreateOnLaunch && openable) {
        // Kısayol akışında açılışta yeni kayıt sheet'i otomatik açılır.
        _onAddPressed();
      }
    });
  }

  @override
  void dispose() {
    _cityCtrl.dispose();
    _districtCtrl.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  bool get _hasSearchFilter => _searchCtrl.text.trim().isNotEmpty;

  void _resetAndLoadPlaces() {
    setState(() {
      _placesLastDoc = null;
      _placeDocs.clear();
    });
    _loadPlaces(reset: true);
  }

  static String _normalizeName(String value) => value
      .trim()
      .toLowerCase()
      .replaceAll(RegExp(r'\s+'), ' ')
      .replaceAll(RegExp(r'[^a-z0-9çğıöşü ]', unicode: true), '')
      .trim();

  Query<Map<String, dynamic>> _placesQuery() {
    // Keep the admin inventory query intentionally broad. Channel, status,
    // type and region filters are applied client-side so the global admin view
    // does not depend on brittle composite indexes and does not hide inactive
    // or legacy records.
    final hasSearch = _hasSearchFilter;
    if (hasSearch) {
      final search = _searchCtrl.text.trim().toLowerCase();
      return FirebaseService.instance.storePlaces
          .orderBy('normalizedName')
          .startAt([search])
          .endAt(['$search\uf8ff'])
          .limit(_pageSize);
    }
    return FirebaseService.instance.storePlaces
        .orderBy('updatedAt', descending: true)
        .limit(_pageSize);
  }

  Future<void> _loadPlaces({bool reset = false}) async {
    if (!mounted || _loadingPlaces) return;
    setState(() => _loadingPlaces = true);
    try {
      var q = _placesQuery();
      if (!reset && _placesLastDoc != null) {
        q = q.startAfterDocument(_placesLastDoc!);
      }
      final snap = await q.get();
      if (!mounted) return;
      setState(() {
        if (reset) _placeDocs.clear();
        _placeDocs.addAll(snap.docs);
        _placesLastDoc = snap.docs.isNotEmpty ? snap.docs.last : _placesLastDoc;
        _hasMorePlaces = snap.docs.length == _pageSize;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Mağazalar yüklenemedi: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _loadingPlaces = false);
    }
  }

  List<QueryDocumentSnapshot<Map<String, dynamic>>> get _filteredPlaceDocs {
    final search = _searchCtrl.text.trim().toLowerCase();
    return _placeDocs.where((d) {
      final m = d.data();
      final city = _cityCtrl.text.trim().toLowerCase();
      final district = _districtCtrl.text.trim().toLowerCase();
      final rowCity =
          (m['cityName'] ?? m['city'] ?? '').toString().toLowerCase();
      final rowDistrict =
          (m['districtName'] ?? m['district'] ?? '').toString().toLowerCase();
      if (city.isNotEmpty && rowCity != city) return false;
      if (district.isNotEmpty && rowDistrict != district) return false;
      if (_status != 'all' && (m['status'] ?? '').toString() != _status) return false;
      final channel = _placeChannelFor(m);
      if (channel != _placeChannel) return false;
      // Fiziksel sekmesinde pazar kayıtları gözükmesin — onlar artık
      // kendi sekmesine taşındı.
      if (_placeChannel == 'physical' &&
          (m['type'] ?? '').toString() == 'bazaar') {
        return false;
      }
      if (_placeChannel != 'bazaar' &&
          _type != 'all' &&
          (m['type'] ?? '').toString() != _type) return false;
      if (search.isNotEmpty) {
        final normalized = (m['normalizedName'] ?? '').toString().toLowerCase();
        final display = (m['displayName'] ?? '').toString().toLowerCase();
        if (!normalized.contains(search) && !display.contains(search)) return false;
      }
      return true;
    }).toList();
  }

  Future<void> _createChainFromSheet() async {
    final messenger = ScaffoldMessenger.of(context);
    final uid = AppStateScope.read(context).user?.uid;
    final result = await _showChainFormSheet(context: context);
    if (!mounted || result == null) return;
    final name = result.name.replaceAll(RegExp(r'\s+'), ' ').trim();
    final normalized = _normalizeName(name);
    if (normalized.isEmpty) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Zincir adı gerekli.')),
      );
      return;
    }
    final duplicate = await FirebaseService.instance.storeChains
        .limit(200)
        .get();
    final hasDuplicate = duplicate.docs.any((d) {
      final data = d.data();
      final existingNormalized = (data['normalizedName'] ?? '').toString();
      final existingName = (data['name'] ?? '').toString();
      return _normalizeName(existingNormalized.isNotEmpty
              ? existingNormalized
              : existingName) ==
          normalized;
    });
    if (hasDuplicate) {
      if (!mounted) return;
      messenger.showSnackBar(
        const SnackBar(content: Text('Bu zincir zaten kayıtlı.')),
      );
      return;
    }
    await FirebaseService.instance.storeChains.add({
      'name': name,
      'normalizedName': normalized,
      'isActive': result.isActive,
      'isPhysicalEnabled': result.isPhysicalEnabled,
      'isOnlineEnabled': result.isOnlineEnabled,
      'supportsPhysical': result.isPhysicalEnabled,
      'supportsOnline': result.isOnlineEnabled,
      'supportedChannels': {
        'physical': result.isPhysicalEnabled,
        'online': result.isOnlineEnabled,
      },
      'createdByUid': uid,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
    if (!mounted) return;
    messenger.showSnackBar(
      const SnackBar(content: Text('Zincir eklendi.')),
    );
  }

  Future<void> _editChainFromSheet(
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    final data = doc.data();
    final result = await _showChainFormSheet(
      context: context,
      initial: data,
      title: 'Zincir düzenle',
    );
    if (!mounted || result == null) return;
    final name = result.name.replaceAll(RegExp(r'\s+'), ' ').trim();
    final normalized = _normalizeName(name);
    if (normalized.isEmpty) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Zincir adı gerekli.')),
      );
      return;
    }
    final duplicate = await FirebaseService.instance.storeChains.limit(200).get();
    final hasDuplicate = duplicate.docs.any((d) {
      if (d.id == doc.id) return false;
      final data = d.data();
      final existingNormalized = (data['normalizedName'] ?? '').toString();
      final existingName = (data['name'] ?? '').toString();
      return _normalizeName(existingNormalized.isNotEmpty
              ? existingNormalized
              : existingName) ==
          normalized;
    });
    if (hasDuplicate) {
      if (!mounted) return;
      messenger.showSnackBar(
        const SnackBar(content: Text('Bu zincir adı zaten kayıtlı.')),
      );
      return;
    }
    await doc.reference.update({
      'name': name,
      'normalizedName': normalized,
      'isActive': result.isActive,
      'isPhysicalEnabled': result.isPhysicalEnabled,
      'isOnlineEnabled': result.isOnlineEnabled,
      'supportsPhysical': result.isPhysicalEnabled,
      'supportsOnline': result.isOnlineEnabled,
      'supportedChannels': {
        'physical': result.isPhysicalEnabled,
        'online': result.isOnlineEnabled,
      },
      'updatedAt': FieldValue.serverTimestamp(),
    });
    if (!mounted) return;
    messenger.showSnackBar(
      const SnackBar(content: Text('Zincir güncellendi.')),
    );
  }

  Future<void> _createPlaceFromSheet({required String channel}) async {
    final uid = AppStateScope.read(context).user?.uid;
    final messenger = ScaffoldMessenger.of(context);
    final result = await _showPlaceFormSheet(
      context: context,
      title: channel == 'online' ? 'Online mağaza ekle' : 'Fiziksel mağaza ekle',
      lockedSourceType: channel,
      initialCity: _cityCtrl.text.trim(),
      initialDistrict: _districtCtrl.text.trim(),
    );
    if (!mounted || result == null) return;
    final name = result.name.replaceAll(RegExp(r'\s+'), ' ').trim();
    final city = result.city.trim();
    final district = result.district.trim();
    final sourceType = result.sourceType;
    if (name.isEmpty) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Mağaza adı gerekli.')),
      );
      return;
    }
    if ((result.chainId ?? '').trim().isEmpty ||
        (result.chainName ?? '').trim().isEmpty) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Önce zincir seç.')),
      );
      return;
    }
    if (sourceType == 'physical' && (city.isEmpty || district.isEmpty)) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Fiziksel mağaza için il ve ilçe seç.')),
      );
      return;
    }
    await FirebaseService.instance.storePlaces.add({
      'chainId': result.chainId,
      'chainName': result.chainName,
      'name': name,
      'displayName': name,
      'normalizedName': _normalizeName(name),
      'type': result.type,
      'sourceType': sourceType,
      'channel': sourceType,
      'city': sourceType == 'online' ? '' : city,
      'cityId': sourceType == 'online' ? '' : city,
      'cityName': sourceType == 'online' ? '' : city,
      'district': sourceType == 'online' ? '' : district,
      'districtId': sourceType == 'online' ? '' : district,
      'districtName': sourceType == 'online' ? '' : district,
      if (result.address.trim().isNotEmpty) 'address': result.address.trim(),
      if (result.websiteUrl.trim().isNotEmpty) 'websiteUrl': result.websiteUrl.trim(),
      if (result.appDeepLink.trim().isNotEmpty) 'appDeepLink': result.appDeepLink.trim(),
      'status': result.status,
      'isActive': true,
      'usageCount': 0,
      'createdByUid': uid,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
    if (!mounted) return;
    if (sourceType == 'physical') {
      setState(() {
        _cityCtrl.text = city;
        _districtCtrl.text = district;
      });
    }
    _resetAndLoadPlaces();
    messenger.showSnackBar(
      const SnackBar(content: Text('Mağaza eklendi.')),
    );
  }

  Future<void> _editPlaceFromSheet(
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    final data = doc.data();
    final result = await _showPlaceFormSheet(
      context: context,
      title: 'Mağaza düzenle',
      lockedSourceType: _placeChannelFor(data),
      initial: data,
    );
    if (!mounted || result == null) return;
    final name = result.name.replaceAll(RegExp(r'\s+'), ' ').trim();
    final city = result.city.trim();
    final district = result.district.trim();
    final sourceType = result.sourceType;
    if (name.isEmpty) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Mağaza adı gerekli.')),
      );
      return;
    }
    if ((result.chainId ?? '').trim().isEmpty ||
        (result.chainName ?? '').trim().isEmpty) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Önce zincir seç.')),
      );
      return;
    }
    if (sourceType == 'physical' && (city.isEmpty || district.isEmpty)) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Fiziksel mağaza için il ve ilçe seç.')),
      );
      return;
    }
    await doc.reference.update({
      'chainId': result.chainId,
      'chainName': result.chainName,
      'name': name,
      'displayName': name,
      'normalizedName': _normalizeName(name),
      'type': result.type,
      'sourceType': sourceType,
      'channel': sourceType,
      'city': sourceType == 'online' ? '' : city,
      'cityId': sourceType == 'online' ? '' : city,
      'cityName': sourceType == 'online' ? '' : city,
      'district': sourceType == 'online' ? '' : district,
      'districtId': sourceType == 'online' ? '' : district,
      'districtName': sourceType == 'online' ? '' : district,
      'address': sourceType == 'physical' ? result.address.trim() : '',
      'websiteUrl': sourceType == 'online' ? result.websiteUrl.trim() : '',
      'appDeepLink': sourceType == 'online' ? result.appDeepLink.trim() : '',
      'status': result.status,
      'updatedAt': FieldValue.serverTimestamp(),
    });
    if (!mounted) return;
    if (sourceType == 'physical') {
      setState(() {
        _cityCtrl.text = city;
        _districtCtrl.text = district;
      });
    }
    _resetAndLoadPlaces();
    messenger.showSnackBar(
      const SnackBar(content: Text('Mağaza güncellendi.')),
    );
  }

  Future<void> _createBazaarFromSheet() async {
    final uid = AppStateScope.read(context).user?.uid;
    final messenger = ScaffoldMessenger.of(context);
    final result = await _showBazaarFormSheet(
      context: context,
      title: 'Mahalle pazarı ekle',
      initialCity: _cityCtrl.text.trim(),
      initialDistrict: _districtCtrl.text.trim(),
    );
    if (!mounted || result == null) return;
    final name = result.name.replaceAll(RegExp(r'\s+'), ' ').trim();
    final city = result.city.trim();
    final district = result.district.trim();
    if (name.isEmpty) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Pazar adı gerekli.')),
      );
      return;
    }
    if (city.isEmpty || district.isEmpty) {
      messenger.showSnackBar(
        const SnackBar(content: Text('İl ve ilçe seçmen gerekli.')),
      );
      return;
    }
    await FirebaseService.instance.storePlaces.add({
      'name': name,
      'displayName': name,
      'normalizedName': _normalizeName(name),
      'type': 'bazaar',
      'sourceType': 'physical',
      'channel': 'physical',
      'city': city,
      'cityId': city,
      'cityName': city,
      'district': district,
      'districtId': district,
      'districtName': district,
      if (result.neighborhood.trim().isNotEmpty)
        'neighborhood': result.neighborhood.trim(),
      if (result.bazaarDay.isNotEmpty) 'bazaarDay': result.bazaarDay,
      'status': result.status,
      'isActive': true,
      'usageCount': 0,
      'createdByUid': uid,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
    if (!mounted) return;
    setState(() {
      _cityCtrl.text = city;
      _districtCtrl.text = district;
    });
    _resetAndLoadPlaces();
    messenger.showSnackBar(
      const SnackBar(content: Text('Mahalle pazarı eklendi.')),
    );
  }

  Future<void> _editBazaarFromSheet(
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    final data = doc.data();
    final result = await _showBazaarFormSheet(
      context: context,
      title: 'Mahalle pazarı düzenle',
      initial: data,
    );
    if (!mounted || result == null) return;
    final name = result.name.replaceAll(RegExp(r'\s+'), ' ').trim();
    final city = result.city.trim();
    final district = result.district.trim();
    if (name.isEmpty) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Pazar adı gerekli.')),
      );
      return;
    }
    if (city.isEmpty || district.isEmpty) {
      messenger.showSnackBar(
        const SnackBar(content: Text('İl ve ilçe seçmen gerekli.')),
      );
      return;
    }
    await doc.reference.update({
      'name': name,
      'displayName': name,
      'normalizedName': _normalizeName(name),
      'type': 'bazaar',
      'sourceType': 'physical',
      'channel': 'physical',
      'city': city,
      'cityId': city,
      'cityName': city,
      'district': district,
      'districtId': district,
      'districtName': district,
      'neighborhood': result.neighborhood.trim(),
      'bazaarDay': result.bazaarDay,
      'status': result.status,
      'updatedAt': FieldValue.serverTimestamp(),
    });
    if (!mounted) return;
    setState(() {
      _cityCtrl.text = city;
      _districtCtrl.text = district;
    });
    _resetAndLoadPlaces();
    messenger.showSnackBar(
      const SnackBar(content: Text('Mahalle pazarı güncellendi.')),
    );
  }

  /// Bir zinciri kalıcı olarak siler. Eğer zincire bağlı `store_places`
  /// kayıtları varsa, admin'i açıkça uyarır ve sayısını gösterir; onay
  /// verirse şubeler orphan kalır (chainId artık geçersiz). Veri kaybı
  /// ciddi olduğundan default davranış sadece zincir doc'unu silmek;
  /// admin gerekirse şubeleri tek tek elle silebilir.
  Future<void> _confirmDeleteChain(
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    final data = doc.data();
    final chainId = doc.id;
    final chainName = (data['name'] ?? '—').toString();

    // Bağlı şube sayısını hızlıca tara (count yerine docs.length — küçük
    // veri seti için yeterli; gerçek count() pahalı index gerektirir).
    int boundCount = 0;
    try {
      final bound = await FirebaseService.instance.storePlaces
          .where('chainId', isEqualTo: chainId)
          .limit(50)
          .get();
      boundCount = bound.docs.length;
    } catch (_) {
      // Index yoksa veya sayım başarısız olursa uyarıyı yine gösterir.
      boundCount = -1;
    }

    final body = boundCount == 0
        ? '$chainName zinciri kalıcı olarak silinecek.\n\nBu işlem geri alınamaz.'
        : boundCount < 0
            ? '$chainName zinciri kalıcı olarak silinecek.\n\nBağlı şube kontrolü yapılamadı — yine de devam etmek istiyor musun?'
            : '$chainName zincirine bağlı $boundCount şube var. '
                'Zinciri silersen bu şubeler orphan kalır (üzerlerinde "Sil" '
                'aksiyonunu kullanman gerekir). Devam etmek istiyor musun?';

    if (!mounted) return;
    final ok = await showAdminConfirmDeleteDialog(
      context,
      title: 'Zinciri sil',
      message: body,
    );
    if (!ok) return;
    try {
      await doc.reference.delete();
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(content: Text('$chainName silindi.')),
      );
    } catch (e) {
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(content: Text('Silinemedi: $e')),
      );
    }
  }

  /// Bir mağaza / şube / online noktayı / mahalle pazarını kalıcı olarak
  /// siler. priceReports koleksiyonundaki `placeId` referansları
  /// dokunulmaz — geçmiş raporlar bozulmaz, sadece artık silinen şubeye
  /// gönderi yapılamaz.
  Future<void> _confirmDeletePlace(
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    final data = doc.data();
    final name = (data['name'] ?? data['displayName'] ?? '—').toString();
    final ok = await showAdminConfirmDeleteDialog(
      context,
      title: 'Mağazayı sil',
      message:
          '$name kalıcı olarak silinecek. Geçmiş fiyat raporları korunur, '
          'ama bu noktaya yeni rapor gönderilemez.\n\nBu işlem geri alınamaz.',
    );
    if (!ok) return;
    try {
      await doc.reference.delete();
      if (!mounted) return;
      setState(() {
        _placeDocs.removeWhere((d) => d.id == doc.id);
      });
      messenger.showSnackBar(
        SnackBar(content: Text('$name silindi.')),
      );
    } catch (e) {
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(content: Text('Silinemedi: $e')),
      );
    }
  }

  Future<void> _runLegacyMigrationBatch() async {
    if (_legacyBusy) return;
    setState(() => _legacyBusy = true);
    try {
      final res = await FirebaseService.instance.migrateLegacyStoresToStorePlaces(
        limit: 50,
        startAfter: _legacyCursor,
      );
      if (!mounted) return;
      setState(() {
        _legacyMigration = res;
        _legacyCursor = res.lastDoc;
      });
    } finally {
      if (mounted) setState(() => _legacyBusy = false);
    }
  }

  Future<void> _migrateMissingRegion(
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
  ) async {
    final uid = AppStateScope.read(context).user?.uid;
    final messenger = ScaffoldMessenger.of(context);
    if (uid == null || uid.isEmpty) return;
    final result = await _showRegionAssignSheet(
      context: context,
      legacyName:
          (doc.data()['name'] ?? doc.data()['displayName'] ?? '').toString(),
    );
    if (result == null) return;
    if (result.city.isEmpty || result.district.isEmpty) return;
    await FirebaseService.instance.migrateSingleLegacyStoreToStorePlace(
      legacyStoreDoc: doc,
      city: result.city,
      district: result.district,
      type: result.type,
      createdByUid: uid,
    );
    if (!mounted) return;
    messenger.showSnackBar(
      const SnackBar(content: Text('Kayıt store_place olarak taşındı.')),
    );
  }

  void _onAddPressed() {
    switch (_tab) {
      case _tabPhysical:
        _createPlaceFromSheet(channel: 'physical');
        break;
      case _tabOnline:
        _createPlaceFromSheet(channel: 'online');
        break;
      case _tabBazaar:
        _createBazaarFromSheet();
        break;
      case _tabLegacy:
        _runLegacyMigrationBatch();
        break;
    }
  }

  IconData get _addIcon =>
      _tab == _tabLegacy ? Icons.sync_rounded : Icons.add_rounded;

  @override
  Widget build(BuildContext context) {
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
                  FRIconChip(icon: _addIcon, onTap: _onAddPressed),
                ],
              ),
            ),
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 14, 20, 0),
              child: FRPageHeader(
                overline: 'ADMIN · MAĞAZA AĞI',
                title: 'Mağaza',
                italicTail: ' yönetimi',
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 42,
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                scrollDirection: Axis.horizontal,
                itemCount: _tabs.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (_, i) => FRFilterChip(
                  _tabs[i],
                  active: _tab == i,
                  onTap: () {
                    final placeTab = i == _tabPhysical ||
                        i == _tabOnline ||
                        i == _tabBazaar;
                    setState(() {
                      _tab = i;
                      if (i == _tabPhysical) _placeChannel = 'physical';
                      if (i == _tabOnline) _placeChannel = 'online';
                      if (i == _tabBazaar) _placeChannel = 'bazaar';
                      if (placeTab) {
                        _placesLastDoc = null;
                        _placeDocs.clear();
                      }
                    });
                    if (placeTab) {
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        if (mounted) _loadPlaces(reset: true);
                      });
                    }
                  },
                ),
              ),
            ),
            // Zincir master listesi artık üst seviye sekme yerine fiziksel /
            // online mağaza listesinin başında inline yönetiliyor. Pazarlar,
            // bekleyen ve eski sekmelerinde gerekmediği için gizliyoruz.
            if (_tab == _tabPhysical || _tab == _tabOnline) ...[
              const SizedBox(height: 14),
              _ChainsInlineManager(
                channel: _placeChannel,
                onCreate: _createChainFromSheet,
                onEdit: _editChainFromSheet,
                onDelete: _confirmDeleteChain,
              ),
            ],
            const SizedBox(height: 14),
            Expanded(child: _buildTab()),
          ],
        ),
      ),
    );
  }

  Widget _buildTab() {
    switch (_tab) {
      case _tabPhysical:
        return _buildPlacesTab(channel: 'physical');
      case _tabOnline:
        return _buildPlacesTab(channel: 'online');
      case _tabBazaar:
        return _buildPlacesTab(channel: 'bazaar');
      case _tabPending:
        return _buildPendingTab();
      default:
        return _buildLegacyTab();
    }
  }

  Widget _buildPlacesTab({required String channel}) {
    final filtered = _filteredPlaceDocs;
    final isBazaar = channel == 'bazaar';
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
      children: [
        _PlacesFilterCard(
          cityCtrl: _cityCtrl,
          districtCtrl: _districtCtrl,
          searchCtrl: _searchCtrl,
          type: _type,
          status: _status,
          showTypeFilter: !isBazaar,
          onSearchChanged: (_) => _resetAndLoadPlaces(),
          onTypeChanged: (v) => setState(() => _type = v),
          onStatusChanged: (v) => setState(() => _status = v),
          onApply: _resetAndLoadPlaces,
        ),
        const SizedBox(height: 14),
        _PlacesSummary(
          city: _cityCtrl.text.trim(),
          district: _districtCtrl.text.trim(),
          type: isBazaar ? 'bazaar' : _type,
          status: _status,
          loadedCount: filtered.length,
        ),
        const SizedBox(height: 12),
        if (filtered.isEmpty && !_loadingPlaces)
          adminEmpty(switch (channel) {
            'online' => 'Henüz online mağaza/kaynak eklenmemiş.',
            'bazaar' => 'Henüz mahalle pazarı eklenmemiş.',
            _ => 'Henüz fiziksel mağaza/şube eklenmemiş.',
          })
        else
          adminRowList([
            for (final d in filtered)
              _PlaceRow(
                data: d.data(),
                onEdit: () => isBazaar
                    ? _editBazaarFromSheet(d)
                    : _editPlaceFromSheet(d),
                onToggleActive: () => d.reference.update({
                  'isActive': !((d.data()['isActive'] as bool?) ?? true),
                  'updatedAt': FieldValue.serverTimestamp(),
                }),
                onDelete: () => _confirmDeletePlace(d),
              ),
          ]),
        const SizedBox(height: 16),
        if (_hasMorePlaces)
          Center(
            child: FRCta(
              label: _loadingPlaces ? 'Yükleniyor…' : 'Daha fazla yükle',
              icon: Icons.expand_more_rounded,
              filled: false,
              onTap: _loadingPlaces ? null : () => _loadPlaces(),
            ),
          )
        else if (_loadingPlaces)
          const AdminLoading(),
      ],
    );
  }

  Widget _buildPendingTab() {
    // Use a single-field query (status='pending') so we don't rely on a
    // composite index being deployed. The pending list is bounded (admins act
    // quickly), so client-side sort/filter is cheap and far more resilient.
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseService.instance.storePlaces
          .where('status', isEqualTo: 'pending')
          .limit(200)
          .snapshots(),
      builder: (_, snap) {
        if (snap.hasError) {
          return Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
            child: adminEmpty(
              'Onay bekleyen kayıtlar yüklenemedi: ${snap.error}',
            ),
          );
        }
        if (snap.connectionState == ConnectionState.waiting) {
          return const AdminLoading();
        }
        final allDocs = snap.data?.docs ?? const [];
        final docs = allDocs
            .where((d) => (d.data()['isActive'] as bool?) ?? true)
            .toList()
          ..sort((a, b) {
            final at = a.data()['updatedAt'];
            final bt = b.data()['updatedAt'];
            final ams = at is Timestamp ? at.millisecondsSinceEpoch : 0;
            final bms = bt is Timestamp ? bt.millisecondsSinceEpoch : 0;
            return bms.compareTo(ams);
          });
        if (docs.isEmpty) {
          return Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
            child: adminEmpty('Onay bekleyen kayıt yok.'),
          );
        }
        return ListView(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(
                '${docs.length} kayıt incelemeni bekliyor',
                style: frText(11.5, FontWeight.w700, color: FR.ink3),
              ),
            ),
            adminRowList([
              for (final d in docs.take(50))
                _PendingRow(
                  data: d.data(),
                  onApprove: () => d.reference.update({
                    'status': 'verified',
                    'updatedAt': FieldValue.serverTimestamp(),
                  }),
                  onReject: () => d.reference.update({
                    'status': 'rejected',
                    'isActive': false,
                    'updatedAt': FieldValue.serverTimestamp(),
                  }),
                ),
            ]),
          ],
        );
      },
    );
  }

  Widget _buildLegacyTab() {
    final res = _legacyMigration;
    final missing = res?.missingRegionDocs ??
        const <QueryDocumentSnapshot<Map<String, dynamic>>>[];
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
      children: [
        _LegacyHeroCard(
          busy: _legacyBusy,
          onMigrate: _runLegacyMigrationBatch,
        ),
        if (res != null) ...[
          const SizedBox(height: 14),
          _MigrationStatsRow(res: res),
        ],
        const SizedBox(height: 18),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Text('BÖLGESİ EKSİK KAYITLAR', style: frOverline()),
        ),
        const SizedBox(height: 8),
        if (missing.isEmpty)
          adminEmpty('Bölge eksik kayıt yok (son batch için).')
        else
          adminRowList([
            for (final d in missing)
              _MissingRegionRow(
                data: d.data(),
                onMigrate: () => _migrateMissingRegion(d),
              ),
          ]),
      ],
    );
  }
}

// ─── Sub-widgets ─────────────────────────────────────────────────────────────

/// "Zincirler" master listesi artık üst seviye sekme değil. Fiziksel /
/// Online mağaza sekmelerinin tepesinde, açılır-kapanır bir kart olarak
/// görünür. Aynı action set: ekle / düzenle / sil / aktif tikle.
class _ChainsInlineManager extends StatefulWidget {
  const _ChainsInlineManager({
    required this.channel,
    required this.onCreate,
    required this.onEdit,
    required this.onDelete,
  });

  /// 'physical' veya 'online' — fiziksel sekmesindeysek sadece fiziksel
  /// kanalı destekleyen zincirleri, online sekmesindeysek online kanalı
  /// destekleyen zincirleri öne çıkartır (deactiveleri yine listede tutar
  /// ama uyarı ile).
  final String channel;
  final Future<void> Function() onCreate;
  final void Function(QueryDocumentSnapshot<Map<String, dynamic>> doc) onEdit;
  final Future<void> Function(QueryDocumentSnapshot<Map<String, dynamic>> doc)
      onDelete;

  @override
  State<_ChainsInlineManager> createState() => _ChainsInlineManagerState();
}

class _ChainsInlineManagerState extends State<_ChainsInlineManager> {
  bool _expanded = false;

  bool _supportsChannel(Map<String, dynamic> data, String channel) {
    final supported = data['supportedChannels'];
    if (supported is Map && supported[channel] is bool) {
      return supported[channel] == true;
    }
    if (channel == 'online') {
      return (data['isOnlineEnabled'] as bool?) ??
          (data['supportsOnline'] as bool?) ??
          false;
    }
    return (data['isPhysicalEnabled'] as bool?) ??
        (data['supportsPhysical'] as bool?) ??
        true;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        decoration: BoxDecoration(
          color: FR.surface,
          borderRadius: FRRad.all(FRRad.l),
          border: Border.all(color: FR.hairline),
        ),
        child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: FirebaseService.instance.storeChains
              .orderBy('name')
              .limit(120)
              .snapshots(),
          builder: (context, snap) {
            final allDocs = snap.data?.docs ??
                const <QueryDocumentSnapshot<Map<String, dynamic>>>[];
            final activeDocs = allDocs.where((d) {
              final m = d.data();
              return ((m['isActive'] as bool?) ?? true) &&
                  _supportsChannel(m, widget.channel);
            }).toList(growable: false);
            final hasError = snap.hasError;
            final loading =
                snap.connectionState == ConnectionState.waiting && !hasError;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                InkWell(
                  onTap: () => setState(() => _expanded = !_expanded),
                  borderRadius: FRRad.all(FRRad.l),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(14, 12, 10, 12),
                    child: Row(
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: FR.gold.withOpacity(.14),
                            borderRadius: FRRad.all(12),
                            border: Border.all(color: FR.goldDeep.withOpacity(.35)),
                          ),
                          child: Icon(Icons.account_tree_rounded,
                              size: 18, color: FR.gold),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Zincirler · master liste',
                                  style: frText(13.5, FontWeight.w800)),
                              const SizedBox(height: 2),
                              Text(
                                loading
                                    ? 'Yükleniyor…'
                                    : hasError
                                        ? 'Liste alınamadı'
                                        : '${activeDocs.length} aktif · şubeler bu zincirlere bağlanır',
                                style: frText(11, FontWeight.w700,
                                    color: FR.ink3),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          tooltip: 'Yeni zincir ekle',
                          onPressed: () async {
                            await widget.onCreate();
                          },
                          icon: Icon(Icons.add_rounded, color: FR.gold),
                          padding: EdgeInsets.zero,
                          constraints:
                              const BoxConstraints(minWidth: 32, minHeight: 32),
                        ),
                        Icon(
                          _expanded
                              ? Icons.expand_less_rounded
                              : Icons.expand_more_rounded,
                          color: FR.ink3,
                        ),
                      ],
                    ),
                  ),
                ),
                if (_expanded) ...[
                  Divider(color: FR.hairline, height: 1),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
                    child: loading
                        ? const Padding(
                            padding: EdgeInsets.symmetric(vertical: 12),
                            child: Center(
                              child: SizedBox(
                                width: 18,
                                height: 18,
                                child:
                                    CircularProgressIndicator(strokeWidth: 2),
                              ),
                            ),
                          )
                        : hasError
                            ? Text(
                                'Zincirler yüklenemedi.',
                                style: frText(12, FontWeight.w700,
                                    color: FR.bad),
                              )
                            : allDocs.isEmpty
                                ? Text(
                                    'Henüz zincir yok. Yukarıdaki + butonu '
                                    'ile yeni bir zincir ekleyebilirsin (ör. A101, BİM).',
                                    style: frText(11.5, FontWeight.w600,
                                        color: FR.ink3, height: 1.45),
                                  )
                                : Wrap(
                                    spacing: 8,
                                    runSpacing: 8,
                                    children: [
                                      for (final d in allDocs)
                                        _InlineChainChip(
                                          data: d.data(),
                                          onEdit: () => widget.onEdit(d),
                                          onDelete: () async =>
                                              widget.onDelete(d),
                                          onToggleActive: () => d.reference
                                              .update({
                                            'isActive': !(((d.data()['isActive']
                                                        as bool?) ??
                                                    true)),
                                            'updatedAt':
                                                FieldValue.serverTimestamp(),
                                          }),
                                          dimIfChannelMismatch:
                                              !_supportsChannel(
                                                  d.data(), widget.channel),
                                        ),
                                    ],
                                  ),
                  ),
                ],
              ],
            );
          },
        ),
      ),
    );
  }
}

class _InlineChainChip extends StatelessWidget {
  const _InlineChainChip({
    required this.data,
    required this.onEdit,
    required this.onDelete,
    required this.onToggleActive,
    required this.dimIfChannelMismatch,
  });

  final Map<String, dynamic> data;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onToggleActive;
  final bool dimIfChannelMismatch;

  @override
  Widget build(BuildContext context) {
    final name = (data['name'] ?? '—').toString();
    final active = (data['isActive'] as bool?) ?? true;
    final disabled = !active || dimIfChannelMismatch;
    return InkWell(
      onTap: onEdit,
      onLongPress: () async {
        final action = await showModalBottomSheet<String>(
          context: context,
          backgroundColor: FR.surface,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          builder: (ctx) => SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: Icon(Icons.edit_rounded, color: FR.gold),
                  title: Text('Düzenle',
                      style: frText(13.5, FontWeight.w800)),
                  onTap: () => Navigator.pop(ctx, 'edit'),
                ),
                ListTile(
                  leading: Icon(
                    active
                        ? Icons.toggle_off_outlined
                        : Icons.toggle_on_outlined,
                    color: FR.ink2,
                  ),
                  title: Text(
                    active ? 'Pasifleştir' : 'Aktif yap',
                    style: frText(13.5, FontWeight.w800),
                  ),
                  onTap: () => Navigator.pop(ctx, 'toggle'),
                ),
                ListTile(
                  leading:
                      Icon(Icons.delete_outline_rounded, color: FR.bad),
                  title: Text('Sil',
                      style: frText(13.5, FontWeight.w800, color: FR.bad)),
                  onTap: () => Navigator.pop(ctx, 'delete'),
                ),
                const SizedBox(height: 4),
              ],
            ),
          ),
        );
        if (action == 'edit') {
          onEdit();
        } else if (action == 'toggle') {
          onToggleActive();
        } else if (action == 'delete') {
          onDelete();
        }
      },
      borderRadius: FRRad.all(999),
      child: Opacity(
        opacity: disabled ? 0.55 : 1,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            color: FR.surfaceHi,
            borderRadius: FRRad.all(999),
            border: Border.all(
              color: active ? FR.goldDeep.withOpacity(.35) : FR.hairline,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.storefront_rounded, size: 13, color: FR.gold),
              const SizedBox(width: 6),
              Text(name,
                  style: frText(12, FontWeight.w800,
                      color: disabled ? FR.ink3 : FR.ink)),
              if (!active) ...[
                const SizedBox(width: 6),
                Text('pasif',
                    style:
                        frText(10, FontWeight.w800, color: FR.warn)),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _PlaceRow extends StatelessWidget {
  const _PlaceRow({
    required this.data,
    required this.onEdit,
    required this.onToggleActive,
    required this.onDelete,
  });
  final Map<String, dynamic> data;
  final VoidCallback onEdit;
  final VoidCallback onToggleActive;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final active = (data['isActive'] as bool?) ?? true;
    final status = (data['status'] ?? 'pending').toString();
    final type = (data['type'] ?? 'local_market').toString();
    final bazaarDay = (data['bazaarDay'] ?? '').toString();
    final dayLabel = type == 'bazaar' ? _bazaarDayLabel(bazaarDay) : '';
    return Container(
      padding: const EdgeInsets.all(14),
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
              Expanded(
                child: Text(
                  (data['name'] ?? data['displayName'] ?? '—').toString(),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: frText(13.5, FontWeight.w800),
                ),
              ),
              const SizedBox(width: 8),
              _StatusPill(status: status),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            [
              _typeLabel(type),
              _placeRegionLabel(data),
              if (dayLabel.isNotEmpty) dayLabel,
            ].join(' · '),
            style: frText(11.5, FontWeight.w700, color: FR.ink3),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                decoration: BoxDecoration(
                  color: (active ? FR.good : FR.ink3).withOpacity(.14),
                  borderRadius: FRRad.all(999),
                  border: Border.all(
                    color: (active ? FR.good : FR.ink3).withOpacity(.3),
                  ),
                ),
                child: Text(
                  active ? 'AKTİF' : 'PASİF',
                  style: frText(10, FontWeight.w800,
                      color: active ? FR.good : FR.ink3, letter: 1.1),
                ),
              ),
              const Spacer(),
              InkWell(
                onTap: onEdit,
                borderRadius: FRRad.all(999),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                  decoration: BoxDecoration(
                    color: FR.surfaceHi,
                    borderRadius: FRRad.all(999),
                    border: Border.all(color: FR.hairline),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.edit_rounded, size: 15, color: FR.ink2),
                      const SizedBox(width: 6),
                      Text(
                        'Düzenle',
                        style: frText(11.5, FontWeight.w800, color: FR.ink),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              InkWell(
                onTap: onToggleActive,
                borderRadius: FRRad.all(999),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                  decoration: BoxDecoration(
                    color: FR.surfaceHi,
                    borderRadius: FRRad.all(999),
                    border: Border.all(color: FR.hairline),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        active
                            ? Icons.toggle_off_rounded
                            : Icons.toggle_on_rounded,
                        size: 16,
                        color: FR.ink2,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        active ? 'Pasifle' : 'Aktif et',
                        style: frText(11.5, FontWeight.w800, color: FR.ink),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              InkWell(
                onTap: onDelete,
                borderRadius: FRRad.all(999),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                  decoration: BoxDecoration(
                    color: FR.bad.withOpacity(.10),
                    borderRadius: FRRad.all(999),
                    border: Border.all(color: FR.bad.withOpacity(.35)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.delete_outline_rounded,
                          size: 16, color: FR.bad),
                      const SizedBox(width: 6),
                      Text(
                        'Sil',
                        style: frText(11.5, FontWeight.w800, color: FR.bad),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PendingRow extends StatelessWidget {
  const _PendingRow({
    required this.data,
    required this.onApprove,
    required this.onReject,
  });
  final Map<String, dynamic> data;
  final VoidCallback onApprove;
  final VoidCallback onReject;

  @override
  Widget build(BuildContext context) {
    final type = (data['type'] ?? '').toString();
    return Container(
      padding: const EdgeInsets.all(14),
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
              Expanded(
                child: Text(
                  (data['name'] ?? data['displayName'] ?? '—').toString(),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: frText(13.5, FontWeight.w800),
                ),
              ),
              const SizedBox(width: 8),
              const _StatusPill(status: 'pending'),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            '${_typeLabel(type)} · '
            '${_placeRegionLabel(data)}',
            style: frText(11.5, FontWeight.w700, color: FR.ink3),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: FRCta(
                  label: 'Reddet',
                  icon: Icons.cancel_outlined,
                  filled: false,
                  height: 44,
                  onTap: onReject,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: FRCta(
                  label: 'Onayla',
                  icon: Icons.check_circle_outline_rounded,
                  height: 44,
                  onTap: onApprove,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MissingRegionRow extends StatelessWidget {
  const _MissingRegionRow({required this.data, required this.onMigrate});
  final Map<String, dynamic> data;
  final VoidCallback onMigrate;

  @override
  Widget build(BuildContext context) {
    final name =
        (data['name'] ?? data['displayName'] ?? '—').toString();
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: FR.surface,
        borderRadius: FRRad.all(FRRad.l),
        border: Border.all(color: FR.hairline),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: FR.warn.withOpacity(.14),
              borderRadius: FRRad.all(10),
              border: Border.all(color: FR.warn.withOpacity(.35)),
            ),
            alignment: Alignment.center,
            child:
                Icon(Icons.warning_amber_rounded, color: FR.warn, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: frText(13, FontWeight.w800)),
                const SizedBox(height: 2),
                Text(
                  'Bölge eksik · taşımak için ata',
                  style: frText(11, FontWeight.w600, color: FR.ink3),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          FRCta(
            label: 'Taşı',
            icon: Icons.east_rounded,
            filled: false,
            height: 38,
            onTap: onMigrate,
          ),
        ],
      ),
    );
  }
}

class _LegacyHeroCard extends StatelessWidget {
  const _LegacyHeroCard({required this.busy, required this.onMigrate});
  final bool busy;
  final VoidCallback onMigrate;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
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
          Text('ESKİ KAYIT KÖPRÜSÜ', style: frOverline()),
          const SizedBox(height: 8),
          Text('Eski stores → store_places',
              style: frDisplay(20, FontWeight.w700)),
          const SizedBox(height: 8),
          Text(
            'Eski market kayıtlarını yeni store_places koleksiyonuna taşı. '
            'Bölgesi eksik kayıtlar aşağıda elle atanmayı bekler.',
            style: frText(12, FontWeight.w600, color: FR.ink2, height: 1.45),
          ),
          const SizedBox(height: 14),
          FRCta(
            label: busy ? 'Çalışıyor…' : '50 kayıt taşı',
            icon: Icons.sync_rounded,
            onTap: busy ? null : onMigrate,
          ),
        ],
      ),
    );
  }
}

class _MigrationStatsRow extends StatelessWidget {
  const _MigrationStatsRow({required this.res});
  final LegacyStoreMigrationResult res;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: _stat('İŞLENEN', '${res.processed}', FR.ink)),
        const SizedBox(width: 8),
        Expanded(child: _stat('YENİ', '${res.migrated}', FR.good)),
        const SizedBox(width: 8),
        Expanded(child: _stat('GÜNCEL', '${res.updated}', FR.gold)),
        const SizedBox(width: 8),
        Expanded(
            child: _stat('EKSİK', '${res.skippedMissingRegion}', FR.warn)),
      ],
    );
  }

  Widget _stat(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: FR.surface,
        borderRadius: FRRad.all(FRRad.m),
        border: Border.all(color: FR.hairline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: frText(9.5, FontWeight.w800,
                  color: FR.ink3, letter: 1.2)),
          const SizedBox(height: 6),
          Text(value, style: frPrice(20, color: color)),
        ],
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.status});
  final String status;

  @override
  Widget build(BuildContext context) {
    final (label, color, icon) = switch (status) {
      'verified' => ('Doğrulandı', FR.good, Icons.verified_rounded),
      'trusted' => ('Güvenilir', FR.gold, Icons.workspace_premium_rounded),
      'pending' => ('Bekliyor', FR.warn, Icons.schedule_rounded),
      'rejected' => ('Reddedildi', FR.bad, Icons.block_rounded),
      _ => ('—', FR.ink3, Icons.help_outline_rounded),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(.14),
        borderRadius: FRRad.all(999),
        border: Border.all(color: color.withOpacity(.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: color),
          const SizedBox(width: 4),
          Text(label, style: frText(10, FontWeight.w800, color: color)),
        ],
      ),
    );
  }
}

class _PlacesSummary extends StatelessWidget {
  const _PlacesSummary({
    required this.city,
    required this.district,
    required this.type,
    required this.status,
    required this.loadedCount,
  });
  final String city;
  final String district;
  final String type;
  final String status;
  final int loadedCount;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            [
              city.isEmpty ? 'Tüm şehirler' : city,
              district.isEmpty ? 'Tüm ilçeler' : district,
              _typeLabel(type),
              _statusLabel(status),
            ].join(' · '),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: frText(11, FontWeight.w700, color: FR.ink3),
          ),
        ),
        const SizedBox(width: 10),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
          decoration: BoxDecoration(
            color: FR.gold.withOpacity(.14),
            borderRadius: FRRad.all(999),
            border: Border.all(color: FR.goldDeep.withOpacity(.35)),
          ),
          child: Text(
            '$loadedCount kayıt',
            style: frText(10.5, FontWeight.w800, color: FR.gold),
          ),
        ),
      ],
    );
  }
}

class _PlacesFilterCard extends StatelessWidget {
  const _PlacesFilterCard({
    required this.cityCtrl,
    required this.districtCtrl,
    required this.searchCtrl,
    required this.type,
    required this.status,
    required this.onSearchChanged,
    required this.onTypeChanged,
    required this.onStatusChanged,
    required this.onApply,
    this.showTypeFilter = true,
  });
  final TextEditingController cityCtrl;
  final TextEditingController districtCtrl;
  final TextEditingController searchCtrl;
  final String type;
  final String status;
  final bool showTypeFilter;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<String> onTypeChanged;
  final ValueChanged<String> onStatusChanged;
  final VoidCallback onApply;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: FR.surface,
        borderRadius: FRRad.all(FRRad.l),
        border: Border.all(color: FR.hairline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('FİLTRE', style: frOverline()),
          const SizedBox(height: 10),
          TextField(
            controller: searchCtrl,
            onChanged: onSearchChanged,
            decoration: InputDecoration(
              hintText: 'Mağaza ara',
              prefixIcon: Icon(Icons.search_rounded, color: FR.ink3),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _RegionFilterTile(
                  cityCtrl: cityCtrl,
                  districtCtrl: districtCtrl,
                  onChanged: onApply,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              if (showTypeFilter) ...[
                Expanded(
                  child: _FilterDropdown(
                    value: type,
                    items: const [
                      ('all', 'Tüm türler'),
                      ('chain_market', 'Zincir'),
                      ('local_market', 'Yerel'),
                      ('online_market', 'Online'),
                    ],
                    onChanged: onTypeChanged,
                  ),
                ),
                const SizedBox(width: 8),
              ],
              Expanded(
                child: _FilterDropdown(
                  value: status,
                  items: const [
                    ('all', 'Tüm statüler'),
                    ('verified', 'Doğrulandı'),
                    ('trusted', 'Güvenilir'),
                    ('pending', 'Bekliyor'),
                    ('rejected', 'Reddedildi'),
                  ],
                  onChanged: onStatusChanged,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerRight,
            child: FRCta(
              label: 'Filtreyi uygula',
              icon: Icons.tune_rounded,
              filled: false,
              height: 42,
              onTap: onApply,
            ),
          ),
        ],
      ),
    );
  }
}

class _RegionFilterTile extends StatefulWidget {
  const _RegionFilterTile({
    required this.cityCtrl,
    required this.districtCtrl,
    required this.onChanged,
  });
  final TextEditingController cityCtrl;
  final TextEditingController districtCtrl;
  final VoidCallback onChanged;

  @override
  State<_RegionFilterTile> createState() => _RegionFilterTileState();
}

class _RegionFilterTileState extends State<_RegionFilterTile> {
  Future<void> _open() async {
    final result = await showRegionPickerSheet(
      context,
      initialCity: widget.cityCtrl.text,
      initialDistrict: widget.districtCtrl.text,
    );
    if (!mounted || result == null) return;
    widget.cityCtrl.text = result.city;
    widget.districtCtrl.text = result.district;
    setState(() {});
    widget.onChanged();
  }

  void _clear() {
    widget.cityCtrl.clear();
    widget.districtCtrl.clear();
    setState(() {});
    widget.onChanged();
  }

  @override
  Widget build(BuildContext context) {
    final city = widget.cityCtrl.text.trim();
    final district = widget.districtCtrl.text.trim();
    final hasRegion = city.isNotEmpty;
    final label = !hasRegion
        ? 'Tüm bölgeler'
        : (district.isEmpty ? city : '$city / $district');
    return InkWell(
      onTap: _open,
      borderRadius: FRRad.all(FRRad.m),
      child: Container(
        height: 48,
        padding: const EdgeInsetsDirectional.fromSTEB(
          FRSpace.m,
          0,
          FRSpace.m,
          0,
        ),
        decoration: BoxDecoration(
          color: FR.surfaceHi,
          borderRadius: FRRad.all(FRRad.m),
          border: Border.all(color: FR.hairline),
        ),
        child: Row(
          children: [
            Icon(Icons.place_outlined, size: 16, color: FR.gold),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                label,
                style: frText(12.5, FontWeight.w700,
                    color: hasRegion ? FR.ink : FR.ink3),
              ),
            ),
            if (hasRegion)
              InkWell(
                onTap: _clear,
                borderRadius: FRRad.all(999),
                child: Padding(
                  padding: const EdgeInsets.all(4),
                  child:
                      Icon(Icons.close_rounded, size: 14, color: FR.ink3),
                ),
              )
            else
              Icon(Icons.keyboard_arrow_down_rounded, color: FR.ink2),
          ],
        ),
      ),
    );
  }
}

class _FilterDropdown extends StatelessWidget {
  const _FilterDropdown({
    required this.value,
    required this.items,
    required this.onChanged,
  });
  final String value;
  final List<(String, String)> items;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final uniqueItems = <(String, String)>[];
    final seenValues = <String>{};
    for (final item in items) {
      if (seenValues.add(item.$1)) uniqueItems.add(item);
    }
    final resolvedValue = seenValues.contains(value)
        ? value
        : (uniqueItems.isEmpty ? null : uniqueItems.first.$1);
    return Container(
      height: 48,
      padding: const EdgeInsetsDirectional.fromSTEB(
          FRSpace.m,
          0,
          FRSpace.m,
          0,
        ),
      decoration: BoxDecoration(
        color: FR.surfaceHi,
        borderRadius: FRRad.all(FRRad.m),
        border: Border.all(color: FR.hairline),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: resolvedValue,
          isExpanded: true,
          dropdownColor: FR.surface,
          icon: Icon(Icons.keyboard_arrow_down_rounded, color: FR.ink2),
          style: frText(12.5, FontWeight.w700, color: FR.ink),
          items: [
            for (final (v, l) in uniqueItems)
              DropdownMenuItem(value: v, child: Text(l)),
          ],
          onChanged: (v) {
            if (v != null) onChanged(v);
          },
        ),
      ),
    );
  }
}

class _SourceChoice extends StatelessWidget {
  const _SourceChoice({
    required this.label,
    required this.icon,
    required this.active,
    required this.onTap,
  });
  final String label;
  final IconData icon;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: FRRad.all(FRRad.m),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        height: 52,
        padding: const EdgeInsetsDirectional.fromSTEB(
          FRSpace.m,
          0,
          FRSpace.m,
          0,
        ),
        decoration: BoxDecoration(
          color: active ? FRPalette.dark.bgElev : FR.surfaceHi,
          borderRadius: FRRad.all(FRRad.m),
          border: Border.all(color: active ? FR.goldDeep : FR.hairline),
          boxShadow: active ? frGoldGlow(opacity: .14) : null,
        ),
        child: Row(
          children: [
            Icon(icon, size: 17, color: active ? FR.gold : FR.ink3),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                label,
                style: frText(
                  12.5,
                  FontWeight.w800,
                  color: active ? FR.surface : FR.ink,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

String _placeChannelFor(Map<String, dynamic> data) {
  final sourceType = (data['sourceType'] ?? data['channel'] ?? '').toString();
  final type = (data['type'] ?? '').toString();
  if (type == 'bazaar') return 'bazaar';
  if (sourceType == 'online' || type == 'online_market') return 'online';
  return 'physical';
}

String _typeLabel(String t) => switch (t) {
      'chain_market' => 'Zincir',
      'local_market' => 'Yerel',
      'online_market' => 'Online',
      'bazaar' => 'Pazar',
      'all' => 'Tüm türler',
      _ => t,
    };

String _bazaarDayLabel(String day) => switch (day.toLowerCase()) {
      'monday' => 'Pazartesi',
      'tuesday' => 'Salı',
      'wednesday' => 'Çarşamba',
      'thursday' => 'Perşembe',
      'friday' => 'Cuma',
      'saturday' => 'Cumartesi',
      'sunday' => 'Pazar',
      _ => '',
    };

String _placeRegionLabel(Map<String, dynamic> data) {
  final type = (data['type'] ?? '').toString();
  final sourceType = (data['sourceType'] ?? '').toString();
  if (type == 'online_market' || sourceType == 'online') return 'Online mağaza';
  final city = (data['cityName'] ?? data['city'] ?? '').toString().trim();
  final district =
      (data['districtName'] ?? data['district'] ?? '').toString().trim();
  final neighborhood = (data['neighborhood'] ?? '').toString().trim();
  if (city.isEmpty && district.isEmpty) return 'Bölge bekliyor';
  final base = district.isEmpty ? city : '$city / $district';
  if (type == 'bazaar' && neighborhood.isNotEmpty) return '$base · $neighborhood';
  return base;
}

String _statusLabel(String s) => switch (s) {
      'verified' => 'Doğrulandı',
      'trusted' => 'Güvenilir',
      'pending' => 'Bekliyor',
      'rejected' => 'Reddedildi',
      'all' => 'Tüm statüler',
      _ => s,
    };

// ─── Bottom sheets ───────────────────────────────────────────────────────────

class _AdminBottomSheetShell extends StatelessWidget {
  const _AdminBottomSheetShell({
    required this.title,
    required this.child,
    this.subtitle,
  });
  final String title;
  final String? subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    return Padding(
      padding: EdgeInsets.only(bottom: mq.viewInsets.bottom),
      child: Container(
        margin: const EdgeInsets.fromLTRB(12, 12, 12, 16),
        padding: const EdgeInsets.fromLTRB(18, 14, 18, 18),
        decoration: BoxDecoration(
          color: FR.surface,
          borderRadius: FRRad.all(FRRad.xl),
          border: Border.all(color: FR.hairline),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: FR.hairline,
                  borderRadius: FRRad.all(999),
                ),
              ),
            ),
            const SizedBox(height: 14),
            Text('ADMIN', style: frOverline()),
            const SizedBox(height: 4),
            Text(title, style: frDisplay(22, FontWeight.w700)),
            if (subtitle != null) ...[
              const SizedBox(height: 4),
              Text(
                subtitle!,
                style: frText(12, FontWeight.w700, color: FR.ink3),
              ),
            ],
            const SizedBox(height: 18),
            child,
          ],
        ),
      ),
    );
  }
}

class _ChainFormResult {
  const _ChainFormResult({
    required this.name,
    required this.isPhysicalEnabled,
    required this.isOnlineEnabled,
    required this.isActive,
  });
  final String name;
  final bool isPhysicalEnabled;
  final bool isOnlineEnabled;
  final bool isActive;
}

Future<_ChainFormResult?> _showChainFormSheet({
  required BuildContext context,
  Map<String, dynamic>? initial,
  String title = 'Zincir ekle',
}) {
  return showModalBottomSheet<_ChainFormResult>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _ChainFormSheetContent(
      initial: initial,
      title: title,
    ),
  );
}

class _ChainFormSheetContent extends StatefulWidget {
  const _ChainFormSheetContent({
    required this.title,
    this.initial,
  });

  final String title;
  final Map<String, dynamic>? initial;

  @override
  State<_ChainFormSheetContent> createState() => _ChainFormSheetContentState();
}

class _ChainFormSheetContentState extends State<_ChainFormSheetContent> {
  late final TextEditingController _ctrl;
  late bool _physical;
  late bool _online;
  late bool _active;

  @override
  void initState() {
    super.initState();
    final initial = widget.initial;
    final supported = initial?['supportedChannels'];
    _ctrl = TextEditingController(text: (initial?['name'] ?? '').toString());
    _physical = (initial?['isPhysicalEnabled'] as bool?) ??
        (initial?['supportsPhysical'] as bool?) ??
        (supported is Map ? (supported['physical'] as bool? ?? true) : true);
    _online = (initial?['isOnlineEnabled'] as bool?) ??
        (initial?['supportsOnline'] as bool?) ??
        (supported is Map ? (supported['online'] as bool? ?? false) : false);
    _active = (initial?['isActive'] as bool?) ?? true;
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _submit() {
    Navigator.pop(
      context,
      _ChainFormResult(
        name: _ctrl.text,
        isPhysicalEnabled: _physical,
        isOnlineEnabled: _online,
        isActive: _active,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final canSave = _ctrl.text.trim().length >= 2 && (_physical || _online);
    return _AdminBottomSheetShell(
      title: widget.title,
      subtitle: 'Marka / kaynak adını ve desteklediği satış kanallarını belirt.',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _ctrl,
            autofocus: true,
            onChanged: (_) => setState(() {}),
            decoration: const InputDecoration(
              hintText: 'Örn. A101, BİM, Migros',
            ),
          ),
          const SizedBox(height: 12),
          SwitchListTile.adaptive(
            value: _physical,
            onChanged: (v) => setState(() => _physical = v),
            title: Text(
              'Fiziksel mağazaları destekler',
              style: frText(12.5, FontWeight.w800),
            ),
            contentPadding: EdgeInsets.zero,
          ),
          SwitchListTile.adaptive(
            value: _online,
            onChanged: (v) => setState(() => _online = v),
            title: Text(
              'Online kaynağı destekler',
              style: frText(12.5, FontWeight.w800),
            ),
            contentPadding: EdgeInsets.zero,
          ),
          SwitchListTile.adaptive(
            value: _active,
            onChanged: (v) => setState(() => _active = v),
            title: Text('Aktif', style: frText(12.5, FontWeight.w800)),
            contentPadding: EdgeInsets.zero,
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: FRCta(
                  label: 'İptal',
                  filled: false,
                  onTap: () => Navigator.pop(context),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: FRCta(
                  label: widget.initial == null ? 'Zinciri ekle' : 'Güncelle',
                  icon: Icons.add_rounded,
                  onTap: canSave ? _submit : null,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ChainDropdownTile extends StatelessWidget {
  const _ChainDropdownTile({
    required this.sourceType,
    required this.selectedId,
    required this.selectedName,
    required this.onChanged,
  });
  final String sourceType;
  final String? selectedId;
  final String? selectedName;
  final void Function(String? id, String? name) onChanged;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseService.instance.storeChains
          .orderBy('name')
          .limit(100)
          .snapshots(),
      builder: (context, snap) {
        if (snap.hasError) return const SizedBox.shrink();
        final docs = (snap.data?.docs ?? const <QueryDocumentSnapshot<Map<String, dynamic>>>[])
            .where((d) {
          final m = d.data();
          if (!((m['isActive'] as bool?) ?? true)) return false;
          final supported = m['supportedChannels'];
          if (supported is Map && supported[sourceType] is bool) {
            return supported[sourceType] == true;
          }
          if (sourceType == 'online') {
            return (m['isOnlineEnabled'] as bool?) ??
                (m['supportsOnline'] as bool?) ??
                true;
          }
          return (m['isPhysicalEnabled'] as bool?) ??
              (m['supportsPhysical'] as bool?) ??
              true;
        }).toList(growable: false);
        if (docs.isEmpty) {
          return Container(
            width: double.infinity,
            padding: const EdgeInsetsDirectional.fromSTEB(
              FRSpace.m,
              FRSpace.m,
              FRSpace.m,
              FRSpace.m,
            ),
            decoration: BoxDecoration(
              color: FR.surfaceHi,
              borderRadius: FRRad.all(FRRad.m),
              border: Border.all(color: FR.hairline),
            ),
            child: Text(
              'Aktif zincir yok; önce Zincirler sekmesinden bir zincir ekle.',
              style: frText(11.5, FontWeight.w700, color: FR.ink3),
            ),
          );
        }
        final hasSelected = selectedId != null && docs.any((d) => d.id == selectedId);
        return _FilterDropdown(
          value: hasSelected ? selectedId! : '__none__',
          items: [
            const ('__none__', 'Zincir seç (zorunlu)'),
            for (final d in docs) (d.id, (d.data()['name'] ?? '—').toString()),
          ],
          onChanged: (v) {
            if (v == '__none__') {
              onChanged(null, null);
              return;
            }
            final d = docs.firstWhere((e) => e.id == v);
            onChanged(d.id, (d.data()['name'] ?? '').toString());
          },
        );
      },
    );
  }
}

String _derivedPlaceName({
  required String sourceType,
  required String? chainName,
  required String? city,
  required String? district,
}) {
  final chain = (chainName ?? '').trim();
  if (chain.isEmpty) return '';
  if (sourceType == 'online') return chain;
  final districtName = (district ?? '').trim();
  if (districtName.isNotEmpty) return '$chain $districtName';
  final cityName = (city ?? '').trim();
  if (cityName.isNotEmpty) return '$chain $cityName';
  return chain;
}

class _PlaceFormResult {
  const _PlaceFormResult({
    required this.name,
    required this.city,
    required this.district,
    required this.type,
    required this.sourceType,
    required this.status,
    required this.chainId,
    required this.chainName,
    required this.address,
    required this.websiteUrl,
    required this.appDeepLink,
  });
  final String name;
  final String city;
  final String district;
  final String type;
  final String sourceType;
  final String status;
  final String? chainId;
  final String? chainName;
  final String address;
  final String websiteUrl;
  final String appDeepLink;
}

Future<_PlaceFormResult?> _showPlaceFormSheet({
  required BuildContext context,
  required String title,
  String initialCity = '',
  String initialDistrict = '',
  String? lockedSourceType,
  Map<String, dynamic>? initial,
}) {
  return showModalBottomSheet<_PlaceFormResult>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _PlaceFormSheetContent(
      title: title,
      initialCity: initialCity,
      initialDistrict: initialDistrict,
      lockedSourceType: lockedSourceType,
      initial: initial,
    ),
  );
}

class _PlaceFormSheetContent extends StatefulWidget {
  const _PlaceFormSheetContent({
    required this.title,
    required this.initialCity,
    required this.initialDistrict,
    this.lockedSourceType,
    this.initial,
  });

  final String title;
  final String initialCity;
  final String initialDistrict;
  final String? lockedSourceType;
  final Map<String, dynamic>? initial;

  @override
  State<_PlaceFormSheetContent> createState() => _PlaceFormSheetContentState();
}

class _PlaceFormSheetContentState extends State<_PlaceFormSheetContent> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _addressCtrl;
  late final TextEditingController _websiteCtrl;
  late final TextEditingController _deepLinkCtrl;
  late String _sourceType;
  late String? _city;
  late String? _district;
  late String? _chainId;
  late String? _chainName;
  late String _type;
  late String _status;

  @override
  void initState() {
    super.initState();
    final initial = widget.initial;
    final initialSourceType = (initial?['sourceType'] ??
            initial?['channel'] ??
            widget.lockedSourceType ??
            'physical')
        .toString();
    final sourceFromType = (initial?['type'] ?? '').toString() == 'online_market'
        ? 'online'
        : initialSourceType;
    final initialCityValue =
        (initial?['cityName'] ?? initial?['city'] ?? widget.initialCity)
            .toString();
    final initialDistrictValue =
        (initial?['districtName'] ?? initial?['district'] ?? widget.initialDistrict)
            .toString();

    _sourceType = widget.lockedSourceType ??
        (sourceFromType == 'online' ? 'online' : 'physical');
    _city = TurkeyLocations.canonicalCity(initialCityValue);
    _district = _city == null
        ? null
        : TurkeyLocations.canonicalDistrict(_city, initialDistrictValue);
    _chainId = (initial?['chainId'] ?? '').toString().trim().isEmpty
        ? null
        : (initial?['chainId'] ?? '').toString();
    _chainName = (initial?['chainName'] ?? '').toString().trim().isEmpty
        ? null
        : (initial?['chainName'] ?? '').toString();
    _type = (initial?['type'] ?? '').toString().trim().isEmpty
        ? (_sourceType == 'online' ? 'online_market' : 'local_market')
        : (initial?['type'] ?? '').toString();
    _status = (initial?['status'] ?? 'verified').toString();

    _nameCtrl = TextEditingController(
      text: (initial?['name'] ?? initial?['displayName'] ?? '').toString(),
    );
    _addressCtrl = TextEditingController(
      text: (initial?['address'] ?? '').toString(),
    );
    _websiteCtrl = TextEditingController(
      text: (initial?['websiteUrl'] ?? '').toString(),
    );
    _deepLinkCtrl = TextEditingController(
      text: (initial?['appDeepLink'] ?? '').toString(),
    );
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _addressCtrl.dispose();
    _websiteCtrl.dispose();
    _deepLinkCtrl.dispose();
    super.dispose();
  }

  String get _derivedName => _derivedPlaceName(
        sourceType: _sourceType,
        chainName: _chainName,
        city: _city,
        district: _district,
      );

  String get _effectiveName {
    final explicit = _nameCtrl.text.trim();
    return explicit.isNotEmpty ? explicit : _derivedName;
  }

  bool get _canSave {
    final hasChain = (_chainId ?? '').trim().isNotEmpty &&
        (_chainName ?? '').trim().isNotEmpty;
    final hasRegion = _sourceType == 'online' ||
        ((_city ?? '').trim().isNotEmpty &&
            (_district ?? '').trim().isNotEmpty);
    return hasChain && _effectiveName.trim().isNotEmpty && hasRegion;
  }

  void _selectSourceType(String value) {
    setState(() {
      _sourceType = value;
      if (value == 'online') {
        _type = 'online_market';
        _city = null;
        _district = null;
      } else if (_type == 'online_market') {
        _type = 'local_market';
      }
    });
  }

  void _selectChain(String? id, String? name) {
    setState(() {
      _chainId = id;
      _chainName = name;
      if (_nameCtrl.text.trim().isEmpty) {
        _nameCtrl.text = _derivedPlaceName(
          sourceType: _sourceType,
          chainName: _chainName,
          city: _city,
          district: _district,
        );
      }
    });
  }

  Future<void> _pickRegion() async {
    final result = await showRegionPickerSheet(
      context,
      initialCity: _city,
      initialDistrict: _district,
    );
    if (!mounted || result == null) return;
    setState(() {
      _city = result.city;
      _district = result.district;
      if (_nameCtrl.text.trim().isEmpty) {
        _nameCtrl.text = _derivedName;
      }
    });
  }

  void _submit() {
    Navigator.pop(
      context,
      _PlaceFormResult(
        name: _effectiveName,
        city: _sourceType == 'online' ? '' : (_city ?? ''),
        district: _sourceType == 'online' ? '' : (_district ?? ''),
        type: _sourceType == 'online' ? 'online_market' : _type,
        sourceType: _sourceType,
        status: _status,
        chainId: _chainId,
        chainName: _chainName,
        address: _addressCtrl.text,
        websiteUrl: _websiteCtrl.text,
        appDeepLink: _deepLinkCtrl.text,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return _AdminBottomSheetShell(
      title: widget.title,
      subtitle: widget.lockedSourceType == null
          ? 'Önce satış kanalını seç: fiziksel veya online'
          : 'Bilgileri güncelle; kanal sabit tutulur.',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _nameCtrl,
            autofocus: true,
            onChanged: (_) => setState(() {}),
            decoration: const InputDecoration(hintText: 'Görünen ad'),
          ),
          const SizedBox(height: 12),
          if (widget.lockedSourceType == null) ...[
            Row(
              children: [
                Expanded(
                  child: _SourceChoice(
                    label: 'Fiziksel mağaza',
                    icon: Icons.storefront_rounded,
                    active: _sourceType == 'physical',
                    onTap: () => _selectSourceType('physical'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _SourceChoice(
                    label: 'Online mağaza',
                    icon: Icons.language_rounded,
                    active: _sourceType == 'online',
                    onTap: () => _selectSourceType('online'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
          ],
          _ChainDropdownTile(
            sourceType: _sourceType,
            selectedId: _chainId,
            selectedName: _chainName,
            onChanged: _selectChain,
          ),
          const SizedBox(height: 10),
          if (_sourceType == 'physical') ...[
            InkWell(
              borderRadius: FRRad.all(FRRad.m),
              onTap: _pickRegion,
              child: Container(
                padding: const EdgeInsetsDirectional.fromSTEB(
                  FRSpace.m,
                  FRSpace.l - 2,
                  FRSpace.m,
                  FRSpace.l - 2,
                ),
                decoration: BoxDecoration(
                  color: FR.surfaceHi,
                  borderRadius: FRRad.all(FRRad.m),
                  border: Border.all(color: FR.hairline),
                ),
                child: Row(
                  children: [
                    Icon(Icons.place_outlined, color: FR.gold, size: 16),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        (_city != null && _district != null)
                            ? '$_city / $_district'
                            : 'İl ve ilçe seç',
                        style: frText(
                          13,
                          FontWeight.w800,
                          color: _city == null ? FR.ink3 : FR.ink,
                        ),
                      ),
                    ),
                    Icon(
                      Icons.keyboard_arrow_right_rounded,
                      size: 18,
                      color: FR.ink2,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 10),
          ] else ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsetsDirectional.fromSTEB(
                FRSpace.m,
                FRSpace.m,
                FRSpace.m,
                FRSpace.m,
              ),
              decoration: BoxDecoration(
                color: FR.gold.withOpacity(.10),
                borderRadius: FRRad.all(FRRad.m),
                border: Border.all(color: FR.goldDeep.withOpacity(.28)),
              ),
              child: Text(
                'Online mağazada il / ilçe zorunlu değildir; fiyat ekleme akışı bunu online kaynak olarak kullanır.',
                style: frText(
                  11.5,
                  FontWeight.w700,
                  color: FR.ink2,
                  height: 1.35,
                ),
              ),
            ),
            const SizedBox(height: 10),
          ],
          if (_sourceType == 'physical') ...[
            TextField(
              controller: _addressCtrl,
              decoration: const InputDecoration(hintText: 'Adres (opsiyonel)'),
            ),
            const SizedBox(height: 10),
          ] else ...[
            TextField(
              controller: _websiteCtrl,
              keyboardType: TextInputType.url,
              decoration: const InputDecoration(
                hintText: 'Web sitesi adresi',
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _deepLinkCtrl,
              keyboardType: TextInputType.url,
              decoration: const InputDecoration(
                hintText: 'Uygulama bağlantısı (opsiyonel)',
              ),
            ),
            const SizedBox(height: 10),
          ],
          Row(
            children: [
              Expanded(
                child: _FilterDropdown(
                  value: _type,
                  items: _sourceType == 'online'
                      ? const [('online_market', 'Online')]
                      : const [
                          ('chain_market', 'Zincir'),
                          ('local_market', 'Yerel'),
                        ],
                  onChanged: (v) => setState(() => _type = v),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _FilterDropdown(
                  value: _status,
                  items: const [
                    ('pending', 'Bekliyor'),
                    ('verified', 'Doğrulandı'),
                    ('trusted', 'Güvenilir'),
                    ('rejected', 'Reddedildi'),
                  ],
                  onChanged: (v) => setState(() => _status = v),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: FRCta(
                  label: 'İptal',
                  filled: false,
                  onTap: () => Navigator.pop(context),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: FRCta(
                  label: widget.initial == null ? 'Kaydet' : 'Güncelle',
                  icon: Icons.check_rounded,
                  onTap: _canSave ? _submit : null,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _BazaarFormResult {
  const _BazaarFormResult({
    required this.name,
    required this.city,
    required this.district,
    required this.neighborhood,
    required this.bazaarDay,
    required this.status,
  });
  final String name;
  final String city;
  final String district;
  final String neighborhood;
  final String bazaarDay;
  final String status;
}

Future<_BazaarFormResult?> _showBazaarFormSheet({
  required BuildContext context,
  required String title,
  String initialCity = '',
  String initialDistrict = '',
  Map<String, dynamic>? initial,
}) {
  return showModalBottomSheet<_BazaarFormResult>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _BazaarFormSheetContent(
      title: title,
      initialCity: initialCity,
      initialDistrict: initialDistrict,
      initial: initial,
    ),
  );
}

class _BazaarFormSheetContent extends StatefulWidget {
  const _BazaarFormSheetContent({
    required this.title,
    required this.initialCity,
    required this.initialDistrict,
    this.initial,
  });

  final String title;
  final String initialCity;
  final String initialDistrict;
  final Map<String, dynamic>? initial;

  @override
  State<_BazaarFormSheetContent> createState() =>
      _BazaarFormSheetContentState();
}

class _BazaarFormSheetContentState extends State<_BazaarFormSheetContent> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _neighborhoodCtrl;
  String? _city;
  String? _district;
  String _bazaarDay = '';
  String _status = 'verified';

  @override
  void initState() {
    super.initState();
    final initial = widget.initial;
    final initialCity =
        (initial?['cityName'] ?? initial?['city'] ?? widget.initialCity)
            .toString();
    final initialDistrict =
        (initial?['districtName'] ?? initial?['district'] ?? widget.initialDistrict)
            .toString();
    _city = TurkeyLocations.canonicalCity(initialCity);
    _district = _city == null
        ? null
        : TurkeyLocations.canonicalDistrict(_city, initialDistrict);
    _bazaarDay = (initial?['bazaarDay'] ?? '').toString();
    _status = (initial?['status'] ?? 'verified').toString();
    _nameCtrl = TextEditingController(
      text: (initial?['name'] ?? initial?['displayName'] ?? '').toString(),
    );
    _neighborhoodCtrl = TextEditingController(
      text: (initial?['neighborhood'] ?? '').toString(),
    );
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _neighborhoodCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickRegion() async {
    final result = await showRegionPickerSheet(
      context,
      initialCity: _city,
      initialDistrict: _district,
    );
    if (!mounted || result == null) return;
    setState(() {
      _city = result.city;
      _district = result.district;
    });
  }

  bool get _canSave {
    return _nameCtrl.text.trim().length >= 2 &&
        (_city ?? '').trim().isNotEmpty &&
        (_district ?? '').trim().isNotEmpty;
  }

  void _submit() {
    Navigator.pop(
      context,
      _BazaarFormResult(
        name: _nameCtrl.text,
        city: _city ?? '',
        district: _district ?? '',
        neighborhood: _neighborhoodCtrl.text,
        bazaarDay: _bazaarDay,
        status: _status,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return _AdminBottomSheetShell(
      title: widget.title,
      subtitle:
          'Pazar adı, il/ilçe, mahalle ve kurulduğu günü gir. Zincir gerekmez.',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _nameCtrl,
            autofocus: true,
            onChanged: (_) => setState(() {}),
            decoration: const InputDecoration(
              hintText: 'Pazar adı (örn. Salı Pazarı)',
            ),
          ),
          const SizedBox(height: 10),
          InkWell(
            borderRadius: FRRad.all(FRRad.m),
            onTap: _pickRegion,
            child: Container(
              padding: const EdgeInsetsDirectional.fromSTEB(
                FRSpace.m,
                FRSpace.l - 2,
                FRSpace.m,
                FRSpace.l - 2,
              ),
              decoration: BoxDecoration(
                color: FR.surfaceHi,
                borderRadius: FRRad.all(FRRad.m),
                border: Border.all(color: FR.hairline),
              ),
              child: Row(
                children: [
                  Icon(Icons.place_outlined, color: FR.gold, size: 16),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      (_city != null && _district != null)
                          ? '$_city / $_district'
                          : 'İl ve ilçe seç',
                      style: frText(
                        13,
                        FontWeight.w800,
                        color: _city == null ? FR.ink3 : FR.ink,
                      ),
                    ),
                  ),
                  Icon(
                    Icons.keyboard_arrow_right_rounded,
                    size: 18,
                    color: FR.ink2,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _neighborhoodCtrl,
            decoration: const InputDecoration(
              hintText: 'Mahalle (opsiyonel)',
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _FilterDropdown(
                  value: _bazaarDay.isEmpty ? '__none__' : _bazaarDay,
                  items: const [
                    ('__none__', 'Pazar günü seç'),
                    ('monday', 'Pazartesi'),
                    ('tuesday', 'Salı'),
                    ('wednesday', 'Çarşamba'),
                    ('thursday', 'Perşembe'),
                    ('friday', 'Cuma'),
                    ('saturday', 'Cumartesi'),
                    ('sunday', 'Pazar'),
                  ],
                  onChanged: (v) => setState(() {
                    _bazaarDay = v == '__none__' ? '' : v;
                  }),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _FilterDropdown(
                  value: _status,
                  items: const [
                    ('pending', 'Bekliyor'),
                    ('verified', 'Doğrulandı'),
                    ('trusted', 'Güvenilir'),
                    ('rejected', 'Reddedildi'),
                  ],
                  onChanged: (v) => setState(() => _status = v),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: FRCta(
                  label: 'İptal',
                  filled: false,
                  onTap: () => Navigator.pop(context),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: FRCta(
                  label: widget.initial == null ? 'Pazarı ekle' : 'Güncelle',
                  icon: Icons.check_rounded,
                  onTap: _canSave ? _submit : null,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _RegionAssignResult {
  const _RegionAssignResult({
    required this.city,
    required this.district,
    required this.type,
  });
  final String city;
  final String district;
  final String type;
}

Future<_RegionAssignResult?> _showRegionAssignSheet({
  required BuildContext context,
  required String legacyName,
}) {
  return showModalBottomSheet<_RegionAssignResult>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _RegionAssignSheetContent(legacyName: legacyName),
  );
}

class _RegionAssignSheetContent extends StatefulWidget {
  const _RegionAssignSheetContent({required this.legacyName});

  final String legacyName;

  @override
  State<_RegionAssignSheetContent> createState() => _RegionAssignSheetContentState();
}

class _RegionAssignSheetContentState extends State<_RegionAssignSheetContent> {
  String? _city;
  String? _district;
  String _type = 'local_market';

  Future<void> _pickRegion() async {
    final result = await showRegionPickerSheet(
      context,
      initialCity: _city,
      initialDistrict: _district,
    );
    if (!mounted || result == null) return;
    setState(() {
      _city = result.city;
      _district = result.district;
    });
  }

  void _submit() {
    final city = _city;
    final district = _district;
    if (city == null || district == null) return;
    Navigator.pop(
      context,
      _RegionAssignResult(
        city: city,
        district: district,
        type: _type,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return _AdminBottomSheetShell(
      title: 'Bölge ata ve taşı',
      subtitle: widget.legacyName,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          InkWell(
            borderRadius: FRRad.all(FRRad.m),
            onTap: _pickRegion,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
              decoration: BoxDecoration(
                color: FR.surfaceHi,
                borderRadius: FRRad.all(FRRad.m),
                border: Border.all(color: FR.hairline),
              ),
              child: Row(
                children: [
                  Icon(Icons.place_outlined, color: FR.gold, size: 16),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      (_city != null && _district != null)
                          ? '$_city / $_district'
                          : 'İl ve ilçe seç',
                      style: frText(
                        13,
                        FontWeight.w800,
                        color: _city == null ? FR.ink3 : FR.ink,
                      ),
                    ),
                  ),
                  Icon(
                    Icons.keyboard_arrow_right_rounded,
                    size: 18,
                    color: FR.ink2,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          _FilterDropdown(
            value: _type,
            items: const [
              ('local_market', 'Yerel'),
              ('chain_market', 'Zincir'),
              ('bazaar', 'Pazar'),
            ],
            onChanged: (v) => setState(() => _type = v),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: FRCta(
                  label: 'İptal',
                  filled: false,
                  onTap: () => Navigator.pop(context),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: FRCta(
                  label: 'Taşı',
                  icon: Icons.east_rounded,
                  onTap: (_city != null && _district != null) ? _submit : null,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
