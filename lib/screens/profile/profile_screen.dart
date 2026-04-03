import 'package:flutter/material.dart';

import '../../theme/neo_design.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return NeoScaffold(
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text('Profil', style: NeoDesign.title()),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: NeoDesign.glassCard(highlighted: true),
            child: Row(
              children: [
                const CircleAvatar(radius: 28, child: Icon(Icons.person)),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Radar Kullanıcısı', style: NeoDesign.title(20)),
                    Text('@fiyatradar', style: NeoDesign.body()),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          ...const [
            _ProfileMenu(title: 'Kayıtlı Fiyatlar', icon: Icons.receipt_long_outlined),
            _ProfileMenu(title: 'Favoriler', icon: Icons.favorite_border),
            _ProfileMenu(title: 'Bildirim Ayarları', icon: Icons.notifications_none),
            _ProfileMenu(title: 'Güvenlik', icon: Icons.lock_outline),
          ]
        ],
      ),
    );
  }
}

class _ProfileMenu extends StatelessWidget {
  const _ProfileMenu({required this.title, required this.icon});

  final String title;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: NeoDesign.glassCard(),
      child: ListTile(
        leading: Icon(icon, color: NeoDesign.secondary),
        title: Text(title, style: NeoDesign.body(color: NeoDesign.text)),
        trailing: const Icon(Icons.chevron_right, color: NeoDesign.muted),
      ),
    );
  }
}
