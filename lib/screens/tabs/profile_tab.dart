import 'package:flutter/material.dart';
import '../../state/app_state.dart';
import '../../theme.dart';

class ProfileTab extends StatelessWidget {
  const ProfileTab({super.key});

  @override
  Widget build(BuildContext context) {
    final state = AppStateScope.of(context);
    final addedCount = state.products
        .where((p) => p.priceHistory.any((e) => e.reportedBy == 'Sen' || e.reportedBy == (state.user?.displayName ?? '')))
        .length;
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
                      label: 'Eklediğin',
                      value: '$addedCount',
                      icon: Icons.add_chart)),
              const SizedBox(width: 12),
              Expanded(
                  child: _StatBox(
                      label: 'Favori',
                      value: '${state.favorites.length}',
                      icon: Icons.favorite_border)),
              const SizedBox(width: 12),
              Expanded(
                  child: _StatBox(
                      label: 'Puan',
                      value: '${state.points}',
                      icon: Icons.star_border)),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: CoffeeColors.crema),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.emoji_events, color: CoffeeColors.caramel),
                    SizedBox(width: 8),
                    Text('Puan Kazan',
                        style: TextStyle(
                            fontWeight: FontWeight.w800,
                            color: CoffeeColors.espresso,
                            fontSize: 16)),
                  ],
                ),
                const SizedBox(height: 10),
                _rewardRow(Icons.add_circle_outline,
                    'Fiyat ekle', '+${PointsRules.addPrice} puan'),
                _rewardRow(Icons.inventory_2_outlined,
                    'Yeni ürün ekle', '+${PointsRules.addProduct} puan'),
                _rewardRow(Icons.favorite_border,
                    'Favorilere ekle', '+${PointsRules.favorite} puan'),
                _rewardRow(Icons.shopping_bag_outlined,
                    'Sepetten alışveriş', '₺10 başına +1 puan'),
                const SizedBox(height: 6),
                Text(
                  '100 puan = ₺${(100 * PointsRules.pointValueTl).toStringAsFixed(2)} indirim',
                  style: const TextStyle(
                      color: CoffeeColors.cocoa, fontSize: 12),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          ..._menuItems.map((m) => _MenuTile(item: m)),
        ],
      ),
    );
  }
}

Widget _rewardRow(IconData icon, String label, String value) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(
      children: [
        Icon(icon, size: 16, color: CoffeeColors.darkRoast),
        const SizedBox(width: 8),
        Expanded(
          child: Text(label,
              style: const TextStyle(
                  color: CoffeeColors.espresso,
                  fontSize: 13,
                  fontWeight: FontWeight.w600)),
        ),
        Text(value,
            style: const TextStyle(
                color: CoffeeColors.caramel,
                fontWeight: FontWeight.w800,
                fontSize: 12)),
      ],
    ),
  );
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
