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
    final isAdmin = (m['isAdmin'] as bool?) == true ||
        (m['role'] as String?) == 'admin';
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
            const SizedBox(height: 14),
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
                  if (docs.isEmpty) {
                    return Padding(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                      child: adminEmpty('Bu filtreyle eşleşen kullanıcı yok.'),
                    );
                  }
                  return ListView(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Text(
                          '${docs.length} kullanıcı listeleniyor · '
                          'toplam ${allDocs.length}',
                          style:
                              frText(11.5, FontWeight.w700, color: FR.ink3),
                        ),
                      ),
                      adminRowList([
                        for (final d in docs)
                          _UserEditRow(uid: d.id, data: d.data()),
                      ]),
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
}


class _UserEditRow extends StatefulWidget {
  const _UserEditRow({required this.uid, required this.data});
  final String uid;
  final Map<String, dynamic> data;

  @override
  State<_UserEditRow> createState() => _UserEditRowState();
}

class _UserEditRowState extends State<_UserEditRow> {
  late final TextEditingController _name =
      TextEditingController(text: (widget.data['displayName'] ?? '').toString());
  late final TextEditingController _username =
      TextEditingController(text: (widget.data['username'] ?? '').toString());
  late final TextEditingController _banReason =
      TextEditingController(text: (widget.data['banReason'] ?? '').toString());
  bool _saving = false;
  bool _roleSaving = false;
  bool _banSaving = false;

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
    final src = (widget.data['displayName'] ??
            widget.data['username'] ??
            widget.data['email'] ??
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
    final isAdmin = (widget.data['isAdmin'] as bool?) == true ||
        (widget.data['role'] as String?) == 'admin';
    final isBanned = (widget.data['isBanned'] as bool?) == true;
    final email = (widget.data['email'] ?? '').toString();
    final displayName = (widget.data['displayName'] ?? '').toString();
    final username = (widget.data['username'] ?? '').toString();
    final trustPercent = widget.data['trustScorePercent'];
    final priceCount = widget.data['priceEntries'];
    final shortUid = widget.uid.length > 8
        ? widget.uid.substring(0, 8)
        : widget.uid;

    return Container(
      decoration: BoxDecoration(
        color: FR.surface,
        borderRadius: FRRad.all(FRRad.l),
        border: Border.all(
          color: isBanned
              ? FR.bad.withOpacity(.45)
              : isAdmin
                  ? FR.goldDeep.withOpacity(.45)
                  : FR.hairline,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header — avatar, name, status pills
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 44,
                  height: 44,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [FR.surfaceHi, FR.surfaceLo],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: FRRad.all(14),
                    border: Border.all(
                      color: isAdmin
                          ? FR.gold.withOpacity(.7)
                          : FR.hairline,
                    ),
                  ),
                  child: Text(
                    _initials(),
                    style: frDisplay(
                      16,
                      FontWeight.w700,
                      color: isAdmin ? FR.gold : FR.ink,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        displayName.isEmpty ? 'İsimsiz kullanıcı' : displayName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: frText(14, FontWeight.w800),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        username.isEmpty ? '—' : '@$username',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style:
                            frText(12, FontWeight.w700, color: FR.ink3),
                      ),
                      if (email.isNotEmpty) ...[
                        const SizedBox(height: 2),
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
                const SizedBox(width: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  alignment: WrapAlignment.end,
                  children: [
                    if (isAdmin) _userPill('ADMIN', FR.gold, Icons.shield_moon_outlined),
                    if (isBanned) _userPill('BANLI', FR.bad, Icons.gpp_bad_rounded),
                    if (!isAdmin && !isBanned)
                      _userPill('AKTİF', FR.good, Icons.check_circle_outline_rounded),
                  ],
                ),
              ],
            ),
          ),

          // Quick metrics
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: FR.surfaceLo,
              border: Border(
                top: BorderSide(color: FR.hairlineSoft),
                bottom: BorderSide(color: FR.hairlineSoft),
              ),
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

          // Editable fields
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 6),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
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
                Align(
                  alignment: Alignment.centerRight,
                  child: SizedBox(
                    width: 160,
                    child: FRCta(
                      label: _saving ? 'Kaydediliyor…' : 'Kaydet',
                      icon: Icons.save_rounded,
                      height: 42,
                      onTap: _saving ? null : _save,
                    ),
                  ),
                ),
              ],
            ),
          ),

          Container(height: 1, color: FR.hairlineSoft),

          // Admin role row
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 8, 12),
            child: Row(
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
                        isAdmin
                            ? 'Tam yönetim erişimi var'
                            : 'Standart kullanıcı',
                        style: frText(11, FontWeight.w600, color: FR.ink3),
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: isAdmin,
                  onChanged: _roleSaving ? null : _toggleAdmin,
                  activeColor: FR.bg,
                  activeTrackColor: FR.gold,
                  inactiveThumbColor: FR.ink2,
                  inactiveTrackColor: FR.surfaceHi,
                ),
              ],
            ),
          ),

          Container(height: 1, color: FR.hairlineSoft),

          // Ban section
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Container(
                      width: 34,
                      height: 34,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: (isBanned ? FR.bad : FR.ink3).withOpacity(.14),
                        borderRadius: FRRad.all(10),
                        border: Border.all(
                          color: (isBanned ? FR.bad : FR.ink3).withOpacity(.35),
                        ),
                      ),
                      child: Icon(
                        isBanned
                            ? Icons.gpp_bad_rounded
                            : Icons.lock_open_rounded,
                        color: isBanned ? FR.bad : FR.ink2,
                        size: 17,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isBanned ? 'Kullanıcı banlı' : 'Kullanıcı aktif',
                            style: frText(13, FontWeight.w800,
                                color: isBanned ? FR.bad : FR.good),
                          ),
                          Text(
                            isBanned
                                ? 'Uygulamaya erişim engellendi'
                                : 'Erişim açık',
                            style: frText(11, FontWeight.w600, color: FR.ink3),
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
                      : (isBanned ? 'Banı kaldır' : 'Bu kullanıcıyı banla'),
                  icon: isBanned
                      ? Icons.lock_open_rounded
                      : Icons.gpp_bad_rounded,
                  filled: !isBanned ? true : false,
                  height: 44,
                  onTap: _banSaving ? null : () => _toggleBan(!isBanned),
                ),
              ],
            ),
          ),
        ],
      ),
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

Future<void> _showTextEditSheet(
  BuildContext context, {
  required String title,
  String initial = '',
  required Future<void> Function(String value) onSave,
}) async {
  final ctrl = TextEditingController(text: initial);
  final ok = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: FR.surface,
      title: Text(title, style: frDisplay(20, FontWeight.w700)),
      content: TextField(
        controller: ctrl,
        decoration: InputDecoration(
          hintText: 'Ad',
          hintStyle: frText(12, FontWeight.w600, color: FR.ink3),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: Text('İptal', style: frText(12.5, FontWeight.w800, color: FR.ink3)),
        ),
        TextButton(
          onPressed: () => Navigator.pop(ctx, true),
          child: Text('Kaydet', style: frText(12.5, FontWeight.w800, color: FR.gold)),
        ),
      ],
    ),
  );
  if (ok == true && ctrl.text.trim().isNotEmpty) {
    try {
      await onSave(ctrl.text.trim());
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$e')),
      );
    }
  }
  ctrl.dispose();
}

Widget adminEmpty(String label) {
  return Container(
    padding: const EdgeInsets.all(20), // LEGACY_EXCEPTION: reason=token_migration owner=codex remove_by=2026-06-30
    decoration: frSurface(radius: FRRad.l),
    alignment: Alignment.center,
    child: Text(label, style: frText(12.5, FontWeight.w600, color: FR.ink3)),
  );
}

Widget adminRowList(List<Widget> rows) {
  return Column(
    children: [
      for (var i = 0; i < rows.length; i++) ...[
        rows[i],
        if (i < rows.length - 1) const SizedBox(height: 10),
      ],
    ],
  );
}

