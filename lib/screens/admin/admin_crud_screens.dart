import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../services/firebase_service.dart';
import '../../ui/components.dart';
import '../../ui/tokens.dart';
import 'admin_shared_widgets.dart';

class AdminStoreCrudScreen extends StatefulWidget {
  const AdminStoreCrudScreen({super.key});

  @override
  State<AdminStoreCrudScreen> createState() => _AdminStoreCrudScreenState();
}

class _AdminStoreCrudScreenState extends State<AdminStoreCrudScreen> {
  static const _pageSize = 50;
  final _searchCtrl = TextEditingController();
  QueryDocumentSnapshot<Map<String, dynamic>>? _lastDoc;
  final List<QueryDocumentSnapshot<Map<String, dynamic>>> _docs = [];
  bool _loading = false;
  bool _hasMore = true;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _initialized || _loading) return;
      _load(reset: true);
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  static String _normalizeName(String value) =>
      value.trim().replaceAll(RegExp(r'\s+'), ' ').toLowerCase();

  Future<QueryDocumentSnapshot<Map<String, dynamic>>?> _findByNormalizedName(
    String normalized, {
    String? excludingDocId,
  }) async {
    final docs = await FirebaseService.instance.stores
        .where('nameNormalized', isEqualTo: normalized)
        .limit(2)
        .get();
    for (final doc in docs.docs) {
      if (excludingDocId != null && doc.id == excludingDocId) continue;
      return doc;
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
    final oldName = (doc.data()['name'] ?? '').toString().trim();
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
    await _syncStoreRenameAcrossProducts(
      oldName: oldName,
      newName: name,
    );
  }

  Future<void> _syncStoreRenameAcrossProducts({
    required String oldName,
    required String newName,
  }) async {
    if (oldName.isEmpty || oldName == newName) return;
    final products = await FirebaseService.instance.products.get();
    final coll = FirebaseService.instance.products;
    final batch = FirebaseService.instance.db.batch();
    var hasWrite = false;
    for (final product in products.docs) {
      final raw = (product.data()['priceHistory'] as List?) ?? const [];
      var changed = false;
      final nextHistory = raw.map((entry) {
        final map = Map<String, dynamic>.from(entry as Map);
        if ((map['store'] ?? '').toString().trim() == oldName) {
          map['store'] = newName;
          changed = true;
        }
        return map;
      }).toList();
      if (changed) {
        batch.update(coll.doc(product.id), {
          'priceHistory': nextHistory,
          'updatedAt': FieldValue.serverTimestamp(),
        });
        hasWrite = true;
      }
    }
    if (hasWrite) {
      await batch.commit();
    }
  }

  Future<void> _load({bool reset = false}) async {
    if (_loading) return;
    if (!reset && !_hasMore) return;
    setState(() => _loading = true);
    try {
      Query<Map<String, dynamic>> q = FirebaseService.instance.stores
          .orderBy(FieldPath.documentId)
          .limit(_pageSize);
      if (!reset && _lastDoc != null) {
        q = q.startAfterDocument(_lastDoc!);
      }
      final snap = await q.get();
      if (!mounted) return;
      setState(() {
        if (reset) _docs.clear();
        _docs.addAll(snap.docs);
        _lastDoc = snap.docs.isNotEmpty ? snap.docs.last : _lastDoc;
        _hasMore = snap.docs.length == _pageSize;
        _initialized = true;
      });
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  List<QueryDocumentSnapshot<Map<String, dynamic>>> get _filteredDocs {
    final q = _searchCtrl.text.trim().toLowerCase();
    final items = [..._docs]
      ..sort((a, b) {
        final ao = (a.data()['order'] as num?)?.toDouble() ?? double.infinity;
        final bo = (b.data()['order'] as num?)?.toDouble() ?? double.infinity;
        if (ao != bo) return ao.compareTo(bo);
        final an = (a.data()['name'] ?? '').toString().toLowerCase();
        final bn = (b.data()['name'] ?? '').toString().toLowerCase();
        return an.compareTo(bn);
      });
    if (q.isEmpty) return items;
    return items.where((d) {
      final name = (d.data()['name'] ?? '').toString().toLowerCase();
      final normalized = (d.data()['nameNormalized'] ?? '').toString().toLowerCase();
      return name.contains(q) || normalized.contains(q);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return AdminCrudScaffold(
      title: 'Market yönetimi (legacy)',
      onAdd: () => showAdminTextEditSheet(
        context,
        title: 'Market ekle',
        onSave: _createStore,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12), // LEGACY_EXCEPTION: reason=token_migration owner=codex remove_by=2026-06-30
            decoration: frSurface(radius: FRRad.m),
            child: Text(
              'Legacy "stores" koleksiyonu yalnızca geriye uyumluluk içindir. '
              'Birincil yönetim: Mağaza Yönetimi > Mağazalar / Noktalar.',
              style: frText(11.5, FontWeight.w700, color: FR.ink3),
            ),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12), // LEGACY_EXCEPTION: reason=token_migration owner=codex remove_by=2026-06-30
            decoration: frSurface(radius: FRRad.m),
            child: TextField(
              controller: _searchCtrl,
              onChanged: (_) => setState(() {}),
              decoration: const InputDecoration(
                border: InputBorder.none,
                hintText: 'Legacy market ara',
              ),
            ),
          ),
          const SizedBox(height: 10),
          if (!_initialized && _loading)
            const Center(child: CircularProgressIndicator())
          else if (_filteredDocs.isEmpty)
            adminEmpty('Legacy market kaydı yok.')
          else
            adminRowList([
              for (final d in _filteredDocs)
                CrudRow(
                  title: (d.data()['name'] ?? '').toString(),
                  subtitle: (d.data()['isActive'] ?? true) ? 'Aktif' : 'Pasif',
                  onEdit: () => showAdminTextEditSheet(
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
            ]),
          if (_hasMore) ...[
            const SizedBox(height: 10),
            Center(
              child: FRCta(
                label: _loading ? 'Yükleniyor…' : 'Daha fazla yükle',
                onTap: _loading ? null : () => _load(),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class AdminCategoryCrudScreen extends StatelessWidget {
  const AdminCategoryCrudScreen({super.key});

  Future<void> _renameCategory(
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
    String rawName,
  ) async {
    final oldName = (doc.data()['name'] ?? '').toString().trim();
    final newName = rawName.trim().replaceAll(RegExp(r'\s+'), ' ');
    await doc.reference.update({'name': newName});
    await _syncCategoryRenameAcrossProducts(
      oldName: oldName,
      newName: newName,
    );
  }

  Future<void> _syncCategoryRenameAcrossProducts({
    required String oldName,
    required String newName,
  }) async {
    if (oldName.isEmpty || oldName == newName) return;
    final products = await FirebaseService.instance.products.get();
    final coll = FirebaseService.instance.products;
    final batch = FirebaseService.instance.db.batch();
    var hasWrite = false;
    for (final product in products.docs) {
      if ((product.data()['category'] ?? '').toString().trim() != oldName) {
        continue;
      }
      batch.update(coll.doc(product.id), {
        'category': newName,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      hasWrite = true;
    }
    if (hasWrite) {
      await batch.commit();
    }
  }

  @override
  Widget build(BuildContext context) {
    final categories = FirebaseService.instance.categories.snapshots();
    return AdminCrudScaffold(
      title: 'Kategori yönetimi',
      onAdd: () => showAdminTextEditSheet(
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
          if (snap.hasError) return adminEmpty('Kategori verisi yüklenemedi.');
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final docs = [...?snap.data?.docs]
            ..sort((a, b) {
              final ao = (a.data()['order'] as num?)?.toDouble() ?? double.infinity;
              final bo = (b.data()['order'] as num?)?.toDouble() ?? double.infinity;
              if (ao != bo) return ao.compareTo(bo);
              final an = (a.data()['name'] ?? '').toString().toLowerCase();
              final bn = (b.data()['name'] ?? '').toString().toLowerCase();
              return an.compareTo(bn);
            });
          if (docs.isEmpty) return adminEmpty('Kategori kaydı yok.');
          return adminRowList([
            for (final d in docs)
              CrudRow(
                title: (d.data()['name'] ?? '').toString(),
                subtitle: (d.data()['isActive'] ?? true) ? 'Aktif' : 'Pasif',
                onEdit: () => showAdminTextEditSheet(
                  context,
                  title: 'Kategori düzenle',
                  initial: (d.data()['name'] ?? '').toString(),
                  onSave: (name) => _renameCategory(d, name),
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

