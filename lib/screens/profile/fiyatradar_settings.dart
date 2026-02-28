import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
// AYIRDIĞIMIZ DOSYALARI İÇERİ ALIYORUZ:
import 'personal_info_screen.dart';
// import 'security_screen.dart';       // Bunları oluşturdukça yorum satırından çıkarırsın
// import 'notification_settings.dart'; // Bunları oluşturdukça yorum satırından çıkarırsın
// import 'about_screen.dart';          // Bunları oluşturdukça yorum satırından çıkarırsın

class FiyatRadarSettingsScreen extends StatelessWidget {
  const FiyatRadarSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F3F0),
      appBar: AppBar(
        backgroundColor: Colors.white.withOpacity(0.95), elevation: 0, centerTitle: true, iconTheme: const IconThemeData(color: Color(0xFF8B4D22)),
        title: const Text('Hesap & Ayarlar', style: TextStyle(color: Color(0xFF2D241E), fontSize: 17, fontWeight: FontWeight.w600)),
        bottom: PreferredSize(preferredSize: const Size.fromHeight(1), child: Container(color: const Color(0x148B4D22), height: 1)),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 24),
        children: [
          _buildSectionTitle('Hesap Yönetimi'),
          _buildInsetGroup([
            _buildListTile(
              icon: Icons.person_outline, 
              title: 'Kişisel Bilgiler & Konum', 
              onTap: () => Navigator.push(context, CupertinoPageRoute(builder: (_) => const PersonalInfoScreen()))
            ),
            _buildDivider(),
            _buildListTile(
              icon: Icons.lock_outline, 
              title: 'Güvenlik ve Giriş', 
              onTap: () {} // SecurityScreen'i bağlayacağız
            ),
          ]),
          const SizedBox(height: 24),

          _buildSectionTitle('Uygulama Tercihleri'),
          _buildInsetGroup([
            _buildListTile(
              icon: Icons.notifications_none, 
              title: 'Bildirim Ayarları', 
              onTap: () {} // NotificationSettingsScreen'i bağlayacağız
            ),
          ]),
          const SizedBox(height: 24),

          _buildSectionTitle('Diğer'),
          _buildInsetGroup([
            _buildListTile(
              icon: Icons.info_outline, 
              title: 'Hakkında ve Destek', 
              onTap: () {} // AboutScreen'i bağlayacağız
            ),
          ]),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(padding: const EdgeInsets.only(left: 36, bottom: 8), child: Text(title.toUpperCase(), style: const TextStyle(color: Color(0xFF8E8A86), fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 0.5)));
  }

  Widget _buildInsetGroup(List<Widget> children) {
    return Container(margin: const EdgeInsets.symmetric(horizontal: 20), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: const Color(0x148B4D22))), child: Column(children: children));
  }

  Widget _buildListTile({required IconData icon, required String title, VoidCallback? onTap}) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      leading: Container(width: 36, height: 36, decoration: BoxDecoration(color: const Color(0x1A8B4D22), borderRadius: BorderRadius.circular(10)), child: Icon(icon, color: const Color(0xFF8B4D22), size: 20)),
      title: Text(title, style: const TextStyle(color: Color(0xFF2D241E), fontSize: 15, fontWeight: FontWeight.w600)),
      trailing: const Icon(Icons.chevron_right, color: Color(0xFF8E8A86)),
      onTap: onTap,
    );
  }

  Widget _buildDivider() => const Divider(height: 1, thickness: 1, color: Color(0x148B4D22), indent: 64);
}
