import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import 'profile_screen.dart';
import 'update_history_screen.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  Future<void> _openUrl(BuildContext context, String rawUrl) async {
    final uri = Uri.parse(rawUrl);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication) && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Bağlantı açılamadı.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F3F0),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFDFBF9).withOpacity(0.95),
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Color(0xFF8B4D22)),
        title: const Text('Hakkında', style: TextStyle(color: Color(0xFF2D241E), fontSize: 17, fontWeight: FontWeight.w600)),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
        children: [
          const SizedBox(height: 6),
          Center(
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: const Color(0xFF8B4D22),
                borderRadius: BorderRadius.circular(20),
                boxShadow: const [BoxShadow(color: Color.fromRGBO(139, 77, 34, 0.35), blurRadius: 22, offset: Offset(0, 9))],
              ),
              child: const Icon(Icons.show_chart_rounded, color: Colors.white, size: 44),
            ),
          ),
          const SizedBox(height: 16),
          const Center(child: Text('FiyatRadar', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: Color(0xFF2D241E)))),
          const Center(child: Text('Sürüm 3.0.0', style: TextStyle(fontSize: 14, color: Color(0xFF8E8A86), fontWeight: FontWeight.w500))),
          const SizedBox(height: 34),
          _section('DESTEK VE BİLGİ'),
          _group([
            _tile(
              'Sıkça Sorulan Sorular (SSS)',
              () => Navigator.of(context).push(CupertinoPageRoute(builder: (_) => const ProfileHelpScreen())),
            ),
            _tile('Bize Ulaşın', () => _openUrl(context, 'mailto:fiyatradar.app@gmail.com')),
            _tile(
              'Güncelleme Geçmişi',
              () => Navigator.of(context).push(CupertinoPageRoute(builder: (_) => const UpdateHistoryScreen())),
            ),
          ]),
          const SizedBox(height: 20),
          _section('YASAL'),
          _group([
            _tile('Kullanım Koşulları', () => _openUrl(context, 'https://fiyatradar.com/kullanim-kosullari')),
            _tile('Gizlilik Politikası', () => _openUrl(context, 'https://fiyatradar.com/gizlilik')),
          ]),
          const SizedBox(height: 28),
          const Center(
            child: Text('© 2026 FiyatRadar A.Ş.\nTüm hakları saklıdır.', textAlign: TextAlign.center, style: TextStyle(fontSize: 12, color: Color(0xFF8E8A86))),
          ),
        ],
      ),
    );
  }

  Widget _section(String text) {
    return Padding(
      padding: const EdgeInsets.only(left: 12, bottom: 8),
      child: Text(text, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF8E8A86), letterSpacing: 0.5)),
    );
  }

  Widget _group(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0x148B4D22)),
      ),
      child: Column(children: children),
    );
  }

  Widget _tile(String title, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 19),
        decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Color(0x148B4D22)))),
        child: Row(
          children: [
            Expanded(child: Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Color(0xFF2D241E)))),
            const Icon(Icons.chevron_right_rounded, color: Color(0xFF8E8A86)),
          ],
        ),
      ),
    );
  }
}
