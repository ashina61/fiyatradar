import 'package:flutter/material.dart';
import '../../theme.dart';

class ProfileTab extends StatelessWidget {
  const ProfileTab({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 100),
        children: [
          const Text('Profil',
              style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  color: CoffeeColors.espresso)),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [CoffeeColors.darkRoast, CoffeeColors.mocha],
              ),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 32,
                  backgroundColor: CoffeeColors.caramel,
                  child: const Text('A',
                      style: TextStyle(
                          color: CoffeeColors.espresso,
                          fontSize: 28,
                          fontWeight: FontWeight.w800)),
                ),
                const SizedBox(width: 16),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Kahve Avcısı',
                          style: TextStyle(
                              color: CoffeeColors.cream,
                              fontSize: 18,
                              fontWeight: FontWeight.w800)),
                      SizedBox(height: 2),
                      Text('@fiyatradar_user',
                          style: TextStyle(
                              color: CoffeeColors.latte, fontSize: 13)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                  child: _StatBox(
                      label: 'Eklediğin', value: '12', icon: Icons.add_chart)),
              const SizedBox(width: 12),
              Expanded(
                  child: _StatBox(
                      label: 'Takip', value: '34', icon: Icons.favorite_border)),
              const SizedBox(width: 12),
              Expanded(
                  child: _StatBox(
                      label: 'Puan', value: '480', icon: Icons.star_border)),
            ],
          ),
          const SizedBox(height: 24),
          ..._menuItems.map((m) => _MenuTile(item: m)),
        ],
      ),
    );
  }
}

class _MenuItem {
  final IconData icon;
  final String title;
  final String subtitle;
  const _MenuItem(this.icon, this.title, this.subtitle);
}

const _menuItems = [
  _MenuItem(Icons.bookmark_outline, 'Kayıtlı Ürünler', 'Takip listende neler var'),
  _MenuItem(Icons.history, 'Geçmiş Eklemeler', 'Senin eklediğin fiyatlar'),
  _MenuItem(Icons.notifications_none, 'Bildirimler', 'Fiyat düşüş alarmları'),
  _MenuItem(Icons.settings_outlined, 'Ayarlar', 'Hesap ve uygulama'),
  _MenuItem(Icons.logout, 'Çıkış Yap', ''),
];

class _StatBox extends StatelessWidget {
  const _StatBox(
      {required this.label, required this.value, required this.icon});
  final String label;
  final String value;
  final IconData icon;
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: CoffeeColors.crema),
      ),
      child: Column(
        children: [
          Icon(icon, color: CoffeeColors.caramel),
          const SizedBox(height: 6),
          Text(value,
              style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: CoffeeColors.espresso)),
          Text(label,
              style: const TextStyle(
                  fontSize: 11, color: CoffeeColors.cocoa)),
        ],
      ),
    );
  }
}

class _MenuTile extends StatelessWidget {
  const _MenuTile({required this.item});
  final _MenuItem item;
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: CoffeeColors.crema),
      ),
      child: ListTile(
        onTap: () {},
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: CoffeeColors.foam,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(item.icon, color: CoffeeColors.darkRoast),
        ),
        title: Text(item.title,
            style: const TextStyle(
                fontWeight: FontWeight.w700,
                color: CoffeeColors.espresso)),
        subtitle: item.subtitle.isEmpty
            ? null
            : Text(item.subtitle,
                style: const TextStyle(color: CoffeeColors.cocoa)),
        trailing: const Icon(Icons.chevron_right, color: CoffeeColors.cocoa),
      ),
    );
  }
}
