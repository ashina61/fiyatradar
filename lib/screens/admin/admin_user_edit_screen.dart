import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../services/firebase_service.dart';
import '../../ui/components.dart';
import '../../ui/tokens.dart';
import 'admin_shared_widgets.dart';

class AdminUserEditScreen extends StatefulWidget {
  const AdminUserEditScreen({super.key});

  @override
  State<AdminUserEditScreen> createState() => _AdminUserEditScreenState();
}

enum _UserFilter { all, admins, banned }

class _AdminUserEditScreenState extends State<AdminUserEditScreen> {
  final _searchCtrl = TextEditingController();
  _UserFilter _filter = _UserFilter.all;

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  bool _matches(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    final m = doc.data();
    final isAdmin = _isAdmin(m);
    final isBanned = (m['isBanned'] as bool?) == true;
    switch (_filter) {
      case _UserFilter.admins:
        if (!isAdmin) return false;
        break;
      case _UserFilter.banned:
        if (!isBanned) return false;
        break;
      case _UserFilter.all:
        break;
    }
    final q = _searchCtrl.text.trim().toLowerCase();
    if (q.isEmpty) return true;
    final name = (m['displayName'] ?? '').toString().toLowerCase();
    final username = (m['username'] ?? '').toString().toLowerCase();
    final email = (m['email'] ?? '').toString().toLowerCase();
    return name.contains(q) || username.contains(q) || email.contains(q) ||
        doc.id.toLowerCase().contains(q);
  }

  static bool _isAdmin(Map<String, dynamic> m) =>
      (m['isAdmin'] as bool?) == true ||
      (m['role'] as String?) == 'admin';

  @override
  Widget build(BuildContext context) {
    final users = FirebaseService.instance.users.limit(500).snapshots();
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
                ],
              ),
            ),
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 14, 20, 0),
              child: FRPageHeader(
                overline: 'ADMIN · TOPLULUK',
                title: 'Kullanıcı',
                italicTail: ' düzenleme',
              ),
            ),
            const SizedBox(height: 14),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: frSurface(radius: FRRad.m),
                child: TextField(
                  controller: _searchCtrl,
                  onChanged: (_) => setState(() {}),
                  style: frText(13, FontWeight.w700),
                  cursorColor: FR.gold,
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    isCollapsed: true,
                    contentPadding: const EdgeInsets.symmetric(vertical: 14),
                    hintText: 'Ad, kullanıcı adı, e-posta veya UID ara…',
                    hintStyle:
                        frText(12.5, FontWeight.w600, color: FR.ink3),
                    icon: Icon(Icons.search_rounded,
                        color: FR.ink3, size: 18),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 36,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                children: [
                  FRFilterChip(
                    'Tümü',
                    active: _filter == _UserFilter.all,
                    onTap: () => setState(() => _filter = _UserFilter.all),
                  ),
                  const SizedBox(width: 8),
                  FRFilterChip(
                    'Adminler',
                    active: _filter == _UserFilter.admins,
                    onTap: () => setState(() => _filter = _UserFilter.admins),
                  ),
                  const SizedBox(width: 8),
                  FRFilterChip(
                    'Banlılar',
                    active: _filter == _UserFilter.banned,
                    onTap: () => setState(() => _filter = _UserFilter.banned),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                stream: users,
                builder: (_, snap) {
                  if (snap.hasError) {
                    return Padding(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                      child: adminEmpty(
                          'Kullanıcı verisi yüklenemedi: ${snap.error}'),
                    );
                  }
                  if (snap.connectionState == ConnectionState.waiting) {
                    return const AdminLoading();
                  }
                  final allDocs = snap.data?.docs ?? const [];
                  final docs = allDocs.where(_matches).toList()
                    ..sort((a, b) {
                      final an =
                          (a.data()['displayName'] ?? '').toString().toLowerCase();
                      final bn =
                          (b.data()['displayName'] ?? '').toString().toLowerCase();
                      return an.compareTo(bn);
                    });
                  final adminCount = allDocs.where((d) => _isAdmin(d.data())).length;
                  final bannedCount = allDocs
                      .where((d) => (d.data()['isBanned'] as bool?) == true)
                      .length;

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                '${docs.length} listeleniyor · '
                                'toplam ${allDocs.length}',
                                style: frText(11.5, FontWeight.w700,
                                    color: FR.ink3),
                              ),
                            ),
                            _summaryDot(
                              label: '$adminCount admin',
                              color: FR.gold,
                            ),
                            const SizedBox(width: 8),
                            _summaryDot(
                              label: '$bannedCount banlı',
                              color: FR.bad,
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: docs.isEmpty
                            ? Padding(
                                padding:
                                    const EdgeInsets.fromLTRB(20, 0, 20, 24),
                                child: adminEmpty(
                                    'Bu filtreyle eşleşen kullanıcı yok.'),
                              )
                            : ListView.separated(
                                padding: const EdgeInsets.fromLTRB(
                                    20, 0, 20, 24),
                                itemCount: docs.length,
                                separatorBuilder: (_, __) =>
                                    const SizedBox(height: 8),
                                itemBuilder: (_, i) {
                                  final d = docs[i];
                                  return _UserRow(
                                    uid: d.id,
                                    data: d.data(),
                                    onTap: () => _openEditor(d.id, d.data()),
                                  );
                                },
                              ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openEditor(
    String uid,
    Map<String, dynamic> data,
  ) async {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: FR.bg,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _UserEditSheet(uid: uid, initialData: data),
    );
  }

  Widget _summaryDot({required String label, required Color color}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(.12),
        borderRadius: FRRad.all(999),
        border: Border.all(color: color.withOpacity(.32)),
      ),
      child: Text(
        label,
        style: frText(10, FontWeight.w800, color: color, letter: .4),
      ),
    );
  }
}

class _UserRow extends StatelessWidget {
  const _UserRow({
    required this.uid,
    required this.data,
    required this.onTap,
  });
  final String uid;
  final Map<String, dynamic> data;
  final VoidCallback onTap;

  bool get _isAdmin =>
      (data['isAdmin'] as bool?) == true || (data['role'] as String?) == 'admin';
  bool get _isBanned => (data['isBanned'] as bool?) == true;

  String get _displayName => (data['displayName'] ?? '').toString();
  String get _username => (data['username'] ?? '').toString();
  String get _email => (data['email'] ?? '').toString();

  String _subtitle() {
    if (_username.isNotEmpty) return '@$_username';
    if (_email.isNotEmpty) return _email;
    return uid.length > 10 ? uid.substring(0, 10) : uid;
  }

  String _initials() {
    final src = _displayName.isNotEmpty
        ? _displayName
        : _username.isNotEmpty
            ? _username
            : _email.isNotEmpty
                ? _email
                : uid;
    if (src.isEmpty) return '?';
    final parts = src.split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.length >= 2) {
      return '${parts.first.characters.first}${parts[1].characters.first}'
          .toUpperCase();
    }
    return src.characters.first.toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final accent = _isBanned
        ? FR.bad
        : _isAdmin
            ? FR.gold
            : null;
    return InkWell(
      onTap: onTap,
      borderRadius: FRRad.all(FRRad.l),
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 10, 10, 10),
        decoration: BoxDecoration(
          color: FR.surface,
          borderRadius: FRRad.all(FRRad.l),
          border: Border.all(
            color: accent?.withOpacity(.45) ?? FR.hairline,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [FR.surfaceHi, FR.surfaceLo],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: FRRad.all(12),
                border: Border.all(
                  color: accent?.withOpacity(.6) ?? FR.hairline,
                ),
              ),
              child: Text(
                _initials(),
                style: frDisplay(
                  13,
                  FontWeight.w700,
                  color: accent ?? FR.ink,
                ),
              ),
            ),
            const SizedBox(width: 11),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _displayName.isEmpty ? 'İsimsiz kullanıcı' : _displayName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: frText(13, FontWeight.w800),
                  ),
                  const SizedBox(height: 1),
                  Text(
                    _subtitle(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: frText(11, FontWeight.w600, color: FR.ink3),
                  ),
                ],
              ),
            ),
            if (_isAdmin || _isBanned) ...[
              const SizedBox(width: 6),
              _statusPill(
                _isBanned ? 'BANLI' : 'ADMIN',
                _isBanned ? FR.bad : FR.gold,
                _isBanned ? Icons.gpp_bad_rounded : Icons.shield_moon_outlined,
              ),
            ],
            const SizedBox(width: 4),
            Icon(Icons.chevron_right_rounded, color: FR.ink3, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _statusPill(String label, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(.14),
        borderRadius: FRRad.all(999),
        border: Border.all(color: color.withOpacity(.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 10, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: frText(9, FontWeight.w800, color: color, letter: 1.0),
          ),
        ],
      ),
    );
  }
}

class _UserEditSheet extends StatefulWidget {
  const _UserEditSheet({required this.uid, required this.initialData});
  final String uid;
  final Map<String, dynamic> initialData;

  @override
  State<_UserEditSheet> createState() => _UserEditSheetState();
}

class _UserEditSheetState extends State<_UserEditSheet> {
  late final TextEditingController _name = TextEditingController(
    text: (widget.initialData['displayName'] ?? '').toString(),
  );
  late final TextEditingController _username = TextEditingController(
    text: (widget.initialData['username'] ?? '').toString(),
  );
  late final TextEditingController _banReason = TextEditingController(
    text: (widget.initialData['banReason'] ?? '').toString(),
  );

  late final Map<String, dynamic> _data = Map<String, dynamic>.from(widget.initialData);
  bool _saving = false;
  bool _roleSaving = false;
  bool _banSaving = false;

  bool get _isAdmin =>
      (_data['isAdmin'] as bool?) == true || (_data['role'] as String?) == 'admin';
  bool get _isBanned => (_data['isBanned'] as bool?) == true;

  @override
  void dispose() {
    _name.dispose();
    _username.dispose();
    _banReason.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      await FirebaseService.instance.users.doc(widget.uid).update({
        'displayName': _name.text.trim(),
        'username': _username.text.trim(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      if (!mounted) return;
      setState(() {
        _data['displayName'] = _name.text.trim();
        _data['username'] = _username.text.trim();
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Kullanıcı bilgileri güncellendi.')),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Kullanıcı bilgileri kaydedilemedi.')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _toggleAdmin(bool v) async {
    if (_roleSaving) return;
    setState(() => _roleSaving = true);
    try {
      await FirebaseService.instance.users.doc(widget.uid).update({
        'isAdmin': v,
        'role': v ? 'admin' : 'user',
        'updatedAt': FieldValue.serverTimestamp(),
      });
      if (!mounted) return;
      setState(() {
        _data['isAdmin'] = v;
        _data['role'] = v ? 'admin' : 'user';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(v ? 'Admin yetkisi verildi.' : 'Admin yetkisi kaldırıldı.')),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Yetki güncellenemedi.')),
      );
    } finally {
      if (mounted) setState(() => _roleSaving = false);
    }
  }

  Future<void> _toggleBan(bool v) async {
    if (_banSaving) return;
    setState(() => _banSaving = true);
    try {
      await FirebaseService.instance.users.doc(widget.uid).update({
        'isBanned': v,
        if (v && _banReason.text.trim().isNotEmpty)
          'banReason': _banReason.text.trim()
        else
          'banReason': FieldValue.delete(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      if (!mounted) return;
      setState(() {
        _data['isBanned'] = v;
        if (v && _banReason.text.trim().isNotEmpty) {
          _data['banReason'] = _banReason.text.trim();
        } else {
          _data.remove('banReason');
        }
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(v ? 'Kullanıcı banlandı.' : 'Ban kaldırıldı.')),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ban işlemi başarısız.')),
      );
    } finally {
      if (mounted) setState(() => _banSaving = false);
    }
  }

  String _initials() {
    final src = (_data['displayName'] ??
            _data['username'] ??
            _data['email'] ??
            '?')
        .toString()
        .trim();
    if (src.isEmpty) return '?';
    final parts = src.split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.length >= 2) {
      return '${parts.first.characters.first}${parts[1].characters.first}'
          .toUpperCase();
    }
    return src.characters.first.toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final email = (_data['email'] ?? '').toString();
    final displayName = (_data['displayName'] ?? '').toString();
    final username = (_data['username'] ?? '').toString();
    final trustPercent = _data['trustScorePercent'];
    final priceCount = _data['priceEntries'];
    final shortUid = widget.uid.length > 8
        ? widget.uid.substring(0, 8)
        : widget.uid;

    final viewInsets = MediaQuery.of(context).viewInsets.bottom;

    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (_, scrollCtrl) {
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: FR.hairline,
                  borderRadius: FRRad.all(999),
                ),
              ),
            ),
            Expanded(
              child: ListView(
                controller: scrollCtrl,
                padding: EdgeInsets.fromLTRB(20, 16, 20, 24 + viewInsets),
                children: [
                  // Header
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [FR.surfaceHi, FR.surfaceLo],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: FRRad.all(14),
                          border: Border.all(
                            color: _isAdmin
                                ? FR.gold.withOpacity(.7)
                                : FR.hairline,
                          ),
                        ),
                        child: Text(
                          _initials(),
                          style: frDisplay(
                            17,
                            FontWeight.w700,
                            color: _isAdmin ? FR.gold : FR.ink,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              displayName.isEmpty
                                  ? 'İsimsiz kullanıcı'
                                  : displayName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: frDisplay(18, FontWeight.w700),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              username.isEmpty ? '—' : '@$username',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: frText(12, FontWeight.w700, color: FR.ink3),
                            ),
                            if (email.isNotEmpty) ...[
                              const SizedBox(height: 1),
                              Text(
                                email,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: frText(11, FontWeight.w600, color: FR.ink3),
                              ),
                            ],
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: Icon(Icons.close_rounded, color: FR.ink3),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      if (_isAdmin)
                        _userPill('ADMIN', FR.gold, Icons.shield_moon_outlined),
                      if (_isBanned)
                        _userPill('BANLI', FR.bad, Icons.gpp_bad_rounded),
                      if (!_isAdmin && !_isBanned)
                        _userPill('AKTİF', FR.good,
                            Icons.check_circle_outline_rounded),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // Metrics
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: FR.surfaceLo,
                      borderRadius: FRRad.all(FRRad.l),
                      border: Border.all(color: FR.hairlineSoft),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: _userMetric(
                            'UID',
                            shortUid,
                            Icons.fingerprint_rounded,
                          ),
                        ),
                        Container(width: 1, height: 22, color: FR.hairline),
                        Expanded(
                          child: _userMetric(
                            'Güven',
                            trustPercent != null ? '%$trustPercent' : '—',
                            Icons.verified_user_outlined,
                          ),
                        ),
                        Container(width: 1, height: 22, color: FR.hairline),
                        Expanded(
                          child: _userMetric(
                            'Fiyat',
                            priceCount != null ? '$priceCount' : '0',
                            Icons.local_offer_outlined,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),

                  // Editable fields
                  _userFieldLabel('AD SOYAD'),
                  _userField(controller: _name, hint: 'Ad Soyad'),
                  const SizedBox(height: 12),
                  _userFieldLabel('KULLANICI ADI'),
                  _userField(
                    controller: _username,
                    hint: 'kullanici_adi',
                    prefix: '@',
                  ),
                  const SizedBox(height: 14),
                  FRCta(
                    label: _saving ? 'Kaydediliyor…' : 'Bilgileri kaydet',
                    icon: Icons.save_rounded,
                    height: 44,
                    onTap: _saving ? null : _save,
                  ),

                  const SizedBox(height: 18),
                  Container(height: 1, color: FR.hairlineSoft),
                  const SizedBox(height: 14),

                  // Admin role row
                  Row(
                    children: [
                      Container(
                        width: 34,
                        height: 34,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: FR.gold.withOpacity(.14),
                          borderRadius: FRRad.all(10),
                          border: Border.all(color: FR.gold.withOpacity(.35)),
                        ),
                        child: Icon(Icons.shield_moon_outlined,
                            color: FR.gold, size: 17),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Admin yetkisi',
                                style: frText(13, FontWeight.w800)),
                            Text(
                              _isAdmin
                                  ? 'Tam yönetim erişimi var'
                                  : 'Standart kullanıcı',
                              style: frText(11, FontWeight.w600, color: FR.ink3),
                            ),
                          ],
                        ),
                      ),
                      Switch(
                        value: _isAdmin,
                        onChanged: _roleSaving ? null : _toggleAdmin,
                        activeColor: FR.bg,
                        activeTrackColor: FR.gold,
                        inactiveThumbColor: FR.ink2,
                        inactiveTrackColor: FR.surfaceHi,
                      ),
                    ],
                  ),

                  const SizedBox(height: 14),
                  Container(height: 1, color: FR.hairlineSoft),
                  const SizedBox(height: 14),

                  // Ban section
                  Row(
                    children: [
                      Container(
                        width: 34,
                        height: 34,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: (_isBanned ? FR.bad : FR.ink3).withOpacity(.14),
                          borderRadius: FRRad.all(10),
                          border: Border.all(
                            color:
                                (_isBanned ? FR.bad : FR.ink3).withOpacity(.35),
                          ),
                        ),
                        child: Icon(
                          _isBanned
                              ? Icons.gpp_bad_rounded
                              : Icons.lock_open_rounded,
                          color: _isBanned ? FR.bad : FR.ink2,
                          size: 17,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _isBanned
                                  ? 'Kullanıcı banlı'
                                  : 'Kullanıcı aktif',
                              style: frText(13, FontWeight.w800,
                                  color: _isBanned ? FR.bad : FR.good),
                            ),
                            Text(
                              _isBanned
                                  ? 'Uygulamaya erişim engellendi'
                                  : 'Erişim açık',
                              style:
                                  frText(11, FontWeight.w600, color: FR.ink3),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _userFieldLabel('BAN NEDENİ (OPSİYONEL)'),
                  _userField(
                    controller: _banReason,
                    hint: 'Ör. spam, sahte fiyat, taciz…',
                    maxLines: 2,
                  ),
                  const SizedBox(height: 12),
                  FRCta(
                    label: _banSaving
                        ? 'İşleniyor…'
                        : (_isBanned ? 'Banı kaldır' : 'Bu kullanıcıyı banla'),
                    icon: _isBanned
                        ? Icons.lock_open_rounded
                        : Icons.gpp_bad_rounded,
                    filled: !_isBanned,
                    height: 44,
                    onTap: _banSaving ? null : () => _toggleBan(!_isBanned),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _userPill(String label, Color color, IconData icon) {
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
          Text(label,
              style:
                  frText(9.5, FontWeight.w800, color: color, letter: 1.1)),
        ],
      ),
    );
  }

  Widget _userMetric(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: FR.ink3, size: 13),
          const SizedBox(width: 6),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(label, style: frOverline(color: FR.ink3, size: 8.5)),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: frText(11.5, FontWeight.w800),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _userFieldLabel(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 6, left: 2),
        child: Text(text, style: frOverline(color: FR.ink3, size: 9.5)),
      );

  Widget _userField({
    required TextEditingController controller,
    required String hint,
    int maxLines = 1,
    String? prefix,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: 12,
        vertical: maxLines > 1 ? 8 : 0,
      ),
      decoration: BoxDecoration(
        color: FR.bgElev,
        borderRadius: FRRad.all(FRRad.m),
        border: Border.all(color: FR.hairline),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (prefix != null) ...[
            Text(prefix,
                style:
                    frText(13.5, FontWeight.w800, color: FR.gold)),
            const SizedBox(width: 4),
          ],
          Expanded(
            child: TextField(
              controller: controller,
              maxLines: maxLines,
              style: frText(13, FontWeight.w700),
              cursorColor: FR.gold,
              decoration: InputDecoration(
                border: InputBorder.none,
                isCollapsed: true,
                contentPadding:
                    EdgeInsets.symmetric(vertical: maxLines > 1 ? 6 : 14),
                hintText: hint,
                hintStyle:
                    frText(12.5, FontWeight.w600, color: FR.ink3),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
