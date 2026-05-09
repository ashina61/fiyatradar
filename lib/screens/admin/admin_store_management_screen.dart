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
  const AdminStoreManagementScreen({super.key});

  @override
  State<AdminStoreManagementScreen> createState() =>
      _AdminStoreManagementScreenState();
}

class _AdminStoreManagementScreenState
    extends State<AdminStoreManagementScreen> {
  static const _pageSize = 50;
  static const _tabs = [
    'Zincirler',
    'Mağazalar',
    'Onay bekleyen',
    'Eski kayıtlar',
  ];

  int _tab = 0;
  final _cityCtrl = TextEditingController();
  final _districtCtrl = TextEditingController();
  final _searchCtrl = TextEditingController();
  String _type = 'all';
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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _loadingPlaces) return;
      _loadPlaces(reset: true);
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
    // Admins need to see every market in the catalog, including the ones a
    // user has flipped to inactive, so we no longer hard-filter by isActive
    // on the server. Use whereIn so the existing composite indexes that key
    // off `isActive` still apply.
    Query<Map<String, dynamic>> q = FirebaseService.instance.storePlaces
        .where('isActive', whereIn: const [true, false]);
    final city = _cityCtrl.text.trim();
    final district = _districtCtrl.text.trim();
    final hasSearch = _hasSearchFilter;
    if (city.isNotEmpty) {
      q = q.where('city', isEqualTo: city);
    }
    if (district.isNotEmpty) {
      q = q.where('district', isEqualTo: district);
    }

    if (hasSearch) {
      final search = _searchCtrl.text.trim().toLowerCase();
      return q
          .orderBy('normalizedName')
          .startAt([search])
          .endAt(['$search\uf8ff'])
          .limit(_pageSize);
    }
    return q.orderBy('updatedAt', descending: true).limit(_pageSize);
  }

  Future<void> _loadPlaces({bool reset = false}) async {
    if (_loadingPlaces) return;
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
      if (city.isNotEmpty &&
          (m['city'] ?? '').toString().toLowerCase() != city) return false;
      if (district.isNotEmpty &&
          (m['district'] ?? '').toString().toLowerCase() != district) return false;
      if (_status != 'all' && (m['status'] ?? '').toString() != _status) return false;
      if (_type != 'all' && (m['type'] ?? '').toString() != _type) return false;
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
    final raw = await _showStoreNameSheet(
      context: context,
      title: 'Yeni zincir',
      subtitle: 'Markette tek başına yer alacak zincirin adı',
      hint: 'Örn. A101, BİM, Migros',
      saveLabel: 'Zinciri ekle',
    );
    if (raw == null) return;
    final name = raw.replaceAll(RegExp(r'\s+'), ' ').trim();
    if (name.isEmpty) return;
    await FirebaseService.instance.storeChains.add({
      'name': name,
      'normalizedName': _normalizeName(name),
      'isActive': true,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
    if (!mounted) return;
    messenger.showSnackBar(
      const SnackBar(content: Text('Zincir eklendi.')),
    );
  }

  Future<void> _createPlaceFromSheet() async {
    final uid = AppStateScope.of(context).user?.uid;
    final messenger = ScaffoldMessenger.of(context);
    final result = await _showPlaceFormSheet(
      context: context,
      title: 'Yeni mağaza',
      initialCity: _cityCtrl.text.trim(),
      initialDistrict: _districtCtrl.text.trim(),
    );
    if (result == null) return;
    final name = result.name.replaceAll(RegExp(r'\s+'), ' ').trim();
    final city = result.city.trim();
    final district = result.district.trim();
    final sourceType = result.sourceType;
    if (name.isEmpty) return;
    if (sourceType == 'physical' && (city.isEmpty || district.isEmpty)) return;
    await FirebaseService.instance.storePlaces.add({
      'displayName': name,
      'normalizedName': _normalizeName(name),
      'type': result.type,
      'sourceType': sourceType,
      'city': sourceType == 'online' ? '' : city,
      'district': sourceType == 'online' ? '' : district,
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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _resetAndLoadPlaces();
    });
    messenger.showSnackBar(
      const SnackBar(content: Text('Mağaza eklendi.')),
    );
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
    final uid = AppStateScope.of(context).user?.uid;
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
    if (_tab == 0) {
      _createChainFromSheet();
    } else if (_tab == 3) {
      _runLegacyMigrationBatch();
    } else {
      _createPlaceFromSheet();
    }
  }

  IconData get _addIcon =>
      _tab == 3 ? Icons.sync_rounded : Icons.add_rounded;

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
                  onTap: () => setState(() => _tab = i),
                ),
              ),
            ),
            const SizedBox(height: 14),
            Expanded(child: _buildTab()),
          ],
        ),
      ),
    );
  }

  Widget _buildTab() {
    switch (_tab) {
      case 0:
        return _buildChainsTab();
      case 1:
        return _buildPlacesTab();
      case 2:
        return _buildPendingTab();
      default:
        return _buildLegacyTab();
    }
  }

  Widget _buildChainsTab() {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseService.instance.storeChains
          .orderBy('updatedAt', descending: true)
          .limit(60)
          .snapshots(),
      builder: (_, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const AdminLoading();
        }
        final docs = snap.data?.docs ?? const [];
        if (docs.isEmpty) {
          return Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
            child: adminEmpty('Henüz zincir kaydı yok.'),
          );
        }
        return ListView(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
          children: [
            adminRowList([
              for (final d in docs)
                _ChainRow(
                  data: d.data(),
                  onToggleActive: (v) => d.reference.update({
                    'isActive': v,
                    'updatedAt': FieldValue.serverTimestamp(),
                  }),
                ),
            ]),
          ],
        );
      },
    );
  }

  Widget _buildPlacesTab() {
    final filtered = _filteredPlaceDocs;
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
      children: [
        _PlacesFilterCard(
          cityCtrl: _cityCtrl,
          districtCtrl: _districtCtrl,
          searchCtrl: _searchCtrl,
          type: _type,
          status: _status,
          onSearchChanged: (_) => _resetAndLoadPlaces(),
          onTypeChanged: (v) => setState(() => _type = v),
          onStatusChanged: (v) => setState(() => _status = v),
          onApply: _resetAndLoadPlaces,
        ),
        const SizedBox(height: 14),
        _PlacesSummary(
          city: _cityCtrl.text.trim(),
          district: _districtCtrl.text.trim(),
          type: _type,
          status: _status,
          loadedCount: filtered.length,
        ),
        const SizedBox(height: 12),
        if (filtered.isEmpty && !_loadingPlaces)
          adminEmpty('Bu filtre için yüklü mağaza yok.')
        else
          adminRowList([
            for (final d in filtered)
              _PlaceRow(
                data: d.data(),
                onToggleActive: () => d.reference.update({
                  'isActive': !((d.data()['isActive'] as bool?) ?? true),
                  'updatedAt': FieldValue.serverTimestamp(),
                }),
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

class _ChainRow extends StatelessWidget {
  const _ChainRow({required this.data, required this.onToggleActive});
  final Map<String, dynamic> data;
  final ValueChanged<bool> onToggleActive;

  @override
  Widget build(BuildContext context) {
    final active = (data['isActive'] as bool?) ?? true;
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
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
            alignment: Alignment.center,
            child: Icon(Icons.storefront_rounded, color: FR.gold, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  (data['name'] ?? '—').toString(),
                  style: frText(13.5, FontWeight.w800),
                ),
                const SizedBox(height: 3),
                Text(
                  active ? 'Aktif zincir' : 'Pasifte',
                  style: frText(11, FontWeight.w700,
                      color: active ? FR.good : FR.ink3),
                ),
              ],
            ),
          ),
          Switch(
            value: active,
            onChanged: onToggleActive,
            activeColor: FR.bg,
            activeTrackColor: FR.gold,
            inactiveThumbColor: FR.ink2,
            inactiveTrackColor: FR.surfaceHi,
          ),
        ],
      ),
    );
  }
}

class _PlaceRow extends StatelessWidget {
  const _PlaceRow({required this.data, required this.onToggleActive});
  final Map<String, dynamic> data;
  final VoidCallback onToggleActive;

  @override
  Widget build(BuildContext context) {
    final active = (data['isActive'] as bool?) ?? true;
    final status = (data['status'] ?? 'pending').toString();
    final type = (data['type'] ?? 'local_market').toString();
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
                  (data['displayName'] ?? '—').toString(),
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
            '${_typeLabel(type)} · '
            '${_placeRegionLabel(data)}',
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
                  (data['displayName'] ?? '—').toString(),
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
            '${city.isEmpty ? "Tüm şehirler" : city}'
            ' · '
            '${district.isEmpty ? "Tüm ilçeler" : district}'
            ' · ${_typeLabel(type)} · ${_statusLabel(status)}',
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
  });
  final TextEditingController cityCtrl;
  final TextEditingController districtCtrl;
  final TextEditingController searchCtrl;
  final String type;
  final String status;
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
              Expanded(
                child: _FilterDropdown(
                  value: type,
                  items: const [
                    ('all', 'Tüm türler'),
                    ('chain_market', 'Zincir'),
                    ('local_market', 'Yerel'),
                    ('online_market', 'Online'),
                    ('bazaar', 'Pazar'),
                  ],
                  onChanged: onTypeChanged,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _FilterDropdown(
                  value: status,
                  items: const [
                    ('all', 'Tüm statüler'),
                    ('verified', 'Verified'),
                    ('trusted', 'Trusted'),
                    ('pending', 'Pending'),
                    ('rejected', 'Rejected'),
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
    if (result == null) return;
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
          value: value,
          isExpanded: true,
          dropdownColor: FR.surface,
          icon: Icon(Icons.keyboard_arrow_down_rounded, color: FR.ink2),
          style: frText(12.5, FontWeight.w700, color: FR.ink),
          items: [
            for (final (v, l) in items)
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

String _typeLabel(String t) => switch (t) {
      'chain_market' => 'Zincir',
      'local_market' => 'Yerel',
      'online_market' => 'Online',
      'bazaar' => 'Pazar',
      'all' => 'Tüm türler',
      _ => t,
    };

String _placeRegionLabel(Map<String, dynamic> data) {
  final type = (data['type'] ?? '').toString();
  final sourceType = (data['sourceType'] ?? '').toString();
  if (type == 'online_market' || sourceType == 'online') return 'Online mağaza';
  final city = (data['city'] ?? '').toString().trim();
  final district = (data['district'] ?? '').toString().trim();
  if (city.isEmpty && district.isEmpty) return 'Bölge bekliyor';
  if (district.isEmpty) return city;
  return '$city / $district';
}

String _statusLabel(String s) => switch (s) {
      'verified' => 'Verified',
      'trusted' => 'Trusted',
      'pending' => 'Pending',
      'rejected' => 'Rejected',
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

Future<String?> _showStoreNameSheet({
  required BuildContext context,
  required String title,
  required String subtitle,
  required String hint,
  required String saveLabel,
}) async {
  final ctrl = TextEditingController();
  try {
    final ok = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _AdminBottomSheetShell(
        title: title,
        subtitle: subtitle,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: ctrl,
              autofocus: true,
              decoration: InputDecoration(hintText: hint),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: FRCta(
                    label: 'İptal',
                    filled: false,
                    onTap: () => Navigator.pop(ctx, false),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: FRCta(
                    label: saveLabel,
                    icon: Icons.add_rounded,
                    onTap: () => Navigator.pop(ctx, true),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
    if (ok != true) return null;
    return ctrl.text;
  } finally {
    ctrl.dispose();
  }
}

class _PlaceFormResult {
  const _PlaceFormResult({
    required this.name,
    required this.city,
    required this.district,
    required this.type,
    required this.sourceType,
    required this.status,
  });
  final String name;
  final String city;
  final String district;
  final String type;
  final String sourceType;
  final String status;
}

Future<_PlaceFormResult?> _showPlaceFormSheet({
  required BuildContext context,
  required String title,
  String initialCity = '',
  String initialDistrict = '',
}) async {
  final nameCtrl = TextEditingController();
  String? city = TurkeyLocations.canonicalCity(initialCity);
  String? district =
      city == null ? null : TurkeyLocations.canonicalDistrict(city, initialDistrict);
  String sourceType = 'physical';
  String type = 'local_market';
  String status = 'verified';
  try {
    final ok = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _AdminBottomSheetShell(
        title: title,
        subtitle: 'Önce satış kanalını seç: fiziksel veya online',
        child: StatefulBuilder(
          builder: (ctx, setInner) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                autofocus: true,
                decoration: const InputDecoration(hintText: 'Görünen ad'),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _SourceChoice(
                      label: 'Fiziksel mağaza',
                      icon: Icons.storefront_rounded,
                      active: sourceType == 'physical',
                      onTap: () => setInner(() {
                        sourceType = 'physical';
                        if (type == 'online_market') type = 'local_market';
                      }),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _SourceChoice(
                      label: 'Online mağaza',
                      icon: Icons.language_rounded,
                      active: sourceType == 'online',
                      onTap: () => setInner(() {
                        sourceType = 'online';
                        type = 'online_market';
                        city = null;
                        district = null;
                      }),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              if (sourceType == 'physical') ...[
                InkWell(
                  borderRadius: FRRad.all(FRRad.m),
                  onTap: () async {
                    final r = await showRegionPickerSheet(
                      ctx,
                      initialCity: city,
                      initialDistrict: district,
                    );
                    if (r != null) {
                      setInner(() {
                        city = r.city;
                        district = r.district;
                      });
                    }
                  },
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
                            (city != null && district != null)
                                ? '$city / $district'
                                : 'İl ve ilçe seç',
                            style: frText(13, FontWeight.w800,
                                color: city == null ? FR.ink3 : FR.ink),
                          ),
                        ),
                        Icon(Icons.keyboard_arrow_right_rounded,
                            size: 18, color: FR.ink2),
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
              Row(
                children: [
                  Expanded(
                    child: _FilterDropdown(
                      value: type,
                      items: sourceType == 'online'
                          ? const [('online_market', 'Online')]
                          : const [
                              ('chain_market', 'Zincir'),
                              ('local_market', 'Yerel'),
                              ('bazaar', 'Pazar'),
                            ],
                      onChanged: (v) => setInner(() => type = v),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _FilterDropdown(
                      value: status,
                      items: const [
                        ('pending', 'Pending'),
                        ('verified', 'Verified'),
                        ('trusted', 'Trusted'),
                      ],
                      onChanged: (v) => setInner(() => status = v),
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
                      onTap: () => Navigator.pop(ctx, false),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: FRCta(
                      label: 'Kaydet',
                      icon: Icons.check_rounded,
                      onTap: () => Navigator.pop(ctx, true),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
    if (ok != true) return null;
    return _PlaceFormResult(
      name: nameCtrl.text,
      city: sourceType == 'online' ? '' : (city ?? ''),
      district: sourceType == 'online' ? '' : (district ?? ''),
      type: sourceType == 'online' ? 'online_market' : type,
      sourceType: sourceType,
      status: status,
    );
  } finally {
    nameCtrl.dispose();
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
}) async {
  String? city;
  String? district;
  String type = 'local_market';
  final ok = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _AdminBottomSheetShell(
        title: 'Bölge ata ve taşı',
        subtitle: legacyName,
        child: StatefulBuilder(
          builder: (ctx, setInner) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              InkWell(
                borderRadius: FRRad.all(FRRad.m),
                onTap: () async {
                  final r = await showRegionPickerSheet(
                    ctx,
                    initialCity: city,
                    initialDistrict: district,
                  );
                  if (r != null) {
                    setInner(() {
                      city = r.city;
                      district = r.district;
                    });
                  }
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 14),
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
                          (city != null && district != null)
                              ? '$city / $district'
                              : 'İl ve ilçe seç',
                          style: frText(13, FontWeight.w800,
                              color: city == null ? FR.ink3 : FR.ink),
                        ),
                      ),
                      Icon(Icons.keyboard_arrow_right_rounded,
                          size: 18, color: FR.ink2),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 10),
              _FilterDropdown(
                value: type,
                items: const [
                  ('local_market', 'Local'),
                  ('chain_market', 'Chain'),
                  ('bazaar', 'Pazar'),
                ],
                onChanged: (v) => setInner(() => type = v),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: FRCta(
                      label: 'İptal',
                      filled: false,
                      onTap: () => Navigator.pop(ctx, false),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: FRCta(
                      label: 'Taşı',
                      icon: Icons.east_rounded,
                      onTap: () => Navigator.pop(ctx, true),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
  );
  if (ok != true) return null;
  if (city == null || district == null) return null;
  return _RegionAssignResult(
    city: city!,
    district: district!,
    type: type,
  );
}
