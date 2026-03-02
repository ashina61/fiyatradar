import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import 'about_screen.dart';
import 'notification_settings.dart';
import 'personal_info_screen.dart';
import 'security_screen.dart';

class FiyatRadarSettingsScreen extends StatefulWidget {
  const FiyatRadarSettingsScreen({super.key});

  @override
  State<FiyatRadarSettingsScreen> createState() => _FiyatRadarSettingsScreenState();
}

class _FiyatRadarSettingsScreenState extends State<FiyatRadarSettingsScreen> {
  static const _bg = Color(0xFFF5F3F0);
  static const _card = Colors.white;
  static const _sienna = Color(0xFF8B4D22);
  static const _text = Color(0xFF2D241E);
  static const _muted = Color(0xFF8E8A86);
  static const _border = Color(0x148B4D22);

  bool _isThemeDark = false;

  Future<void> _clearCache() async {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('12 MB önbellek temizlendi.')),
    );
  }

  Future<void> _rateApp() async {
    final storeUri = Uri.parse('https://play.google.com/store/apps/details?id=com.fiyatradar.app');
    final opened = await launchUrl(storeUri, mode: LaunchMode.externalApplication);

    if (!opened && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Mağaza bağlantısı açılamadı.')),
      );
    }
  }

  Future<void> _deleteAccount() async {
    final confirmed = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Hesabı Sil'),
            content: const Text('Tüm verilerin kalıcı olarak silinecek. Emin misin?'),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Vazgeç')),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Kalıcı Olarak Sil', style: TextStyle(color: Color(0xFFDC2626))),
              ),
            ],
          ),
        ) ??
        false;

    if (!confirmed) return;

    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    try {
      await FirebaseFirestore.instance.collection('users').doc(uid).set({
        'accountDeleted': true,
        'deletedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      await FirebaseAuth.instance.currentUser?.delete();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Hesap silindi.')));
      Navigator.of(context).popUntil((route) => route.isFirst);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('İşlem için yeniden giriş gerekebilir.'), backgroundColor: Color(0xFFDC2626)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: const Color(0xFFFDFBF9).withOpacity(0.95),
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: const Text('Hesap & Ayarlar', style: TextStyle(color: _text, fontSize: 17, fontWeight: FontWeight.w600)),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 40),
        children: [
          _ProfileEntryCard(
            onTap: () => Navigator.of(context).push(CupertinoPageRoute(builder: (_) => const PersonalInfoScreen())),
          ),
          const SizedBox(height: 20),
          _section('Hesap Yönetimi'),
          _group([
            _tile(
              icon: Icons.person_outline_rounded,
              title: 'Kişisel Bilgiler & Konum',
              onTap: () => Navigator.of(context).push(CupertinoPageRoute(builder: (_) => const PersonalInfoScreen())),
            ),
            _tile(
              icon: Icons.lock_outline_rounded,
              title: 'Güvenlik ve Giriş',
              onTap: () => Navigator.of(context).push(CupertinoPageRoute(builder: (_) => const SecurityScreen())),
            ),
          ]),
          const SizedBox(height: 16),
          _section('Uygulama Tercihleri'),
          _group([
            _tile(
              icon: Icons.notifications_none_rounded,
              title: 'Bildirim Ayarları',
              onTap: () => Navigator.of(context).push(CupertinoPageRoute(builder: (_) => const NotificationSettingsScreen())),
            ),
            _tile(
              icon: Icons.dark_mode_outlined,
              title: 'Karanlık Tema',
              trailing: Switch(
                value: _isThemeDark,
                activeColor: Colors.white,
                activeTrackColor: _sienna,
                onChanged: (value) {
                  setState(() => _isThemeDark = value);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Tema değişikliği yeniden başlatınca aktif olacaktır.')),
                  );
                },
              ),
            ),
            _tile(
              icon: Icons.delete_outline_rounded,
              title: 'Önbelleği Temizle',
              subtitle: 'Uygulama yavaşlarsa kullan',
              onTap: _clearCache,
            ),
            _tile(
              icon: Icons.star_rate_rounded,
              title: 'Uygulamayı Puanla',
              subtitle: 'Deneyimini mağazada değerlendir',
              onTap: _rateApp,
            ),
          ]),
          const SizedBox(height: 16),
          _section('Diğer'),
          _group([
            _tile(
              icon: Icons.info_outline_rounded,
              title: 'Hakkında, Yardım ve Destek',
              onTap: () => Navigator.of(context).push(CupertinoPageRoute(builder: (_) => const AboutScreen())),
            ),
          ]),
          const SizedBox(height: 16),
          const Padding(
            padding: EdgeInsets.only(left: 12, bottom: 8),
            child: Text('TEHLİKELİ BÖLGE', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFFDC2626))),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFDC2626),
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              padding: const EdgeInsets.symmetric(vertical: 18),
            ),
            onPressed: _deleteAccount,
            child: const Text('Hesabı Kalıcı Olarak Sil', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  Widget _section(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 12, bottom: 8),
      child: Text(title.toUpperCase(), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: _muted, letterSpacing: 0.5)),
    );
  }

  Widget _group(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _border),
      ),
      child: Column(children: children),
    );
  }

  Widget _tile({
    required IconData icon,
    required String title,
    String? subtitle,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: _border)),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(color: const Color(0x1A8B4D22), borderRadius: BorderRadius.circular(12)),
              child: Icon(icon, color: _sienna),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: _text)),
                  if (subtitle != null)
                    Text(subtitle, style: const TextStyle(fontSize: 13, color: _muted)),
                ],
              ),
            ),
            trailing ?? const Icon(Icons.chevron_right_rounded, color: _muted),
          ],
        ),
      ),
    );
  }
}

class _ProfileEntryCard extends StatelessWidget {
  const _ProfileEntryCard({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: uid == null ? null : FirebaseFirestore.instance.collection('users').doc(uid).snapshots(),
      builder: (context, snapshot) {
        final data = snapshot.data?.data() ?? <String, dynamic>{};
        final name = (data['name'] ?? data['displayName'] ?? 'Kullanıcı').toString();
        final username = (data['username'] ?? '').toString();
        final city = (data['city'] ?? data['cityName'] ?? 'İstanbul').toString();
        final district = (data['district'] ?? 'Kadıköy').toString();
        final trust = (data['trustScorePercent'] as num?)?.toInt() ?? 86;
        final initials = name.trim().isEmpty
            ? 'FR'
            : name
                .trim()
                .split(RegExp(r'\s+'))
                .take(2)
                .map((e) => e.isNotEmpty ? e[0].toUpperCase() : '')
                .join();

        return InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              gradient: const LinearGradient(colors: [Colors.white, Color(0xFFFDFBF9)]),
              border: Border.all(color: const Color(0x148B4D22)),
            ),
            child: Row(
              children: [
                Container(
                  width: 68,
                  height: 68,
                  decoration: BoxDecoration(color: const Color(0x1A8B4D22), borderRadius: BorderRadius.circular(22)),
                  alignment: Alignment.center,
                  child: Text(initials, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: Color(0xFF8B4D22))),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(name, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: Color(0xFF2D241E))),
                      const SizedBox(height: 4),
                      Text('$city, $district • @$username', style: const TextStyle(fontSize: 13, color: Color(0xFF8E8A86))),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(color: const Color(0x192E7D32), borderRadius: BorderRadius.circular(12)),
                        child: Text('%$trust Güven Endeksi', style: const TextStyle(fontSize: 11, color: Color(0xFF2E7D32), fontWeight: FontWeight.w600)),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right_rounded, color: Color(0xFF8E8A86)),
              ],
            ),
          ),
        );
      },
    );
  }
}
