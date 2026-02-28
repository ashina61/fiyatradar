import 'package:flutter/material.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F3F0),
      appBar: AppBar(
        backgroundColor: Colors.white.withOpacity(0.95), elevation: 0, centerTitle: true, iconTheme: const IconThemeData(color: Color(0xFF8B4D22)),
        title: const Text('Hakkında', style: TextStyle(color: Color(0xFF2D241E), fontSize: 17, fontWeight: FontWeight.w600)),
        bottom: PreferredSize(preferredSize: const Size.fromHeight(1), child: Container(color: const Color(0x148B4D22), height: 1)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const SizedBox(height: 20),
          Center(
            child: Container(
              width: 80, height: 80,
              decoration: BoxDecoration(color: const Color(0xFF8B4D22), borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: const Color(0xFF8B4D22).withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 8))]),
              child: const Icon(Icons.radar, color: Colors.white, size: 40),
            ),
          ),
          const SizedBox(height: 16),
          const Center(child: Text('FiyatRadar', style: TextStyle(color: Color(0xFF2D241E), fontSize: 22, fontWeight: FontWeight.bold))),
          const Center(child: Text('Sürüm 3.0.0', style: TextStyle(color: Color(0xFF8E8A86), fontSize: 14))),
          const SizedBox(height: 40),

          Container(
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: const Color(0x148B4D22))),
            child: Column(
              children: [
                _buildListTile('Kullanım Koşulları'),
                const Divider(height: 1, color: Color(0x148B4D22), indent: 20),
                _buildListTile('Gizlilik Politikası'),
                const Divider(height: 1, color: Color(0x148B4D22), indent: 20),
                _buildListTile('Bize Ulaşın (Destek)'),
              ],
            ),
          ),
          const SizedBox(height: 40),
          const Center(child: Text('© 2026 FiyatRadar A.Ş.\nTüm Hakları Saklıdır.', textAlign: TextAlign.center, style: TextStyle(color: Color(0xFF8E8A86), fontSize: 12))),
        ],
      ),
    );
  }

  Widget _buildListTile(String title) {
    return ListTile(
      title: Text(title, style: const TextStyle(color: Color(0xFF2D241E), fontSize: 15, fontWeight: FontWeight.w500)),
      trailing: const Icon(Icons.chevron_right, color: Color(0xFF8E8A86)),
      onTap: () {},
    );
  }
}
