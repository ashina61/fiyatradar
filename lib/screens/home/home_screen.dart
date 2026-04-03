import 'package:flutter/material.dart';

import '../../theme/neo_design.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return NeoScaffold(
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text('Ana Sayfa', style: NeoDesign.title()),
          const SizedBox(height: 8),
          Text('Yeni tasarım dilinin merkez paneli.', style: NeoDesign.body()),
          const SizedBox(height: 16),
          _card('Bugünün Özeti', '12 markette 428 fiyat güncellendi', Icons.insights_outlined, true),
          const SizedBox(height: 12),
          _card('Öne Çıkan Fırsat', 'Temel gıda sepetinde %14 avantaj', Icons.local_offer_outlined, false),
          const SizedBox(height: 12),
          _card('Topluluk Nabzı', '1.204 yeni fiyat bildirimi', Icons.groups_outlined, false),
        ],
      ),
    );
  }

  Widget _card(String title, String subtitle, IconData icon, bool highlighted) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: NeoDesign.glassCard(highlighted: highlighted),
      child: Row(
        children: [
          Icon(icon, color: NeoDesign.secondary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: NeoDesign.title(18)),
                const SizedBox(height: 4),
                Text(subtitle, style: NeoDesign.body()),
              ],
            ),
          )
        ],
      ),
    );
  }
}
