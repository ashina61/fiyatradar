import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../services/firebase_service.dart';
import '../widgets/prototype_ui.dart';

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> with SingleTickerProviderStateMixin {
  late final TabController _tc = TabController(length: 6, vsync: this);

  @override
  void dispose() {
    _tc.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Panel'),
        bottom: TabBar(
          controller: _tc,
          isScrollable: true,
          labelColor: ProtoColors.tan,
          unselectedLabelColor: ProtoColors.textSubtle,
          tabs: const [
            Tab(text: 'Dashboard'),
            Tab(text: 'Ürünler'),
            Tab(text: 'Bannerlar'),
            Tab(text: 'Kategoriler'),
            Tab(text: 'Kullanıcılar'),
            Tab(text: 'Bildirimler'),
          ],
        ),
      ),
      body: TabBarView(controller: _tc, children: const [
        _Dashboard(),
        _Products(),
        _Banners(),
        _Categories(),
        _Users(),
        _Notifications(),
      ]),
    );
  }
}

class _Dashboard extends StatelessWidget {
  const _Dashboard();

  @override
  Widget build(BuildContext context) {
    final svc = FirebaseService.instance;
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: svc.products.snapshots(),
      builder: (context, pSnap) {
        return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: svc.users.snapshots(),
          builder: (context, uSnap) {
            final p = pSnap.data?.docs.length ?? 0;
            final u = uSnap.data?.docs.length ?? 0;
            return ListView(
              padding: const EdgeInsets.all(24),
              children: [
                GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  children: [
                    _stat('Toplam Ürün', '$p', ProtoColors.success),
                    _stat('Aktif Kullanıcı', '$u', ProtoColors.purple),
                    _stat('Bu Hafta Eklenen', '482', ProtoColors.warning),
                    _stat('Aktif Alarm', '89', ProtoColors.danger),
                  ],
                ),
                const SizedBox(height: 14),
                const ProtoCard(child: Text('Dashboard tablosu prototype ile aynı gramerde hazırlanmıştır.')),
              ],
            );
          },
        );
      },
    );
  }

  Widget _stat(String l, String v, Color c) => Container(
        padding: const EdgeInsets.all(14),
        decoration: protoSurface(radius: ProtoRadius.lg),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          CircleAvatar(radius: 18, backgroundColor: c.withOpacity(0.2), child: Icon(Icons.analytics_outlined, color: c, size: 18)),
          const SizedBox(height: 10),
          Text(v, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800)),
          Text(l, style: const TextStyle(fontSize: 11, color: ProtoColors.textSubtle)),
        ]),
      );
}

class _Products extends StatelessWidget {
  const _Products();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseService.instance.products.snapshots(),
      builder: (context, snap) {
        final docs = snap.data?.docs ?? [];
        return ListView(
          padding: const EdgeInsets.all(24),
          children: docs
              .take(20)
              .map((d) => Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    child: ProtoCard(
                      child: Row(children: [
                        const CircleAvatar(radius: 16, backgroundColor: ProtoColors.surfaceAlt, child: Text('📦')),
                        const SizedBox(width: 10),
                        Expanded(child: Text((d.data()['name'] ?? '-') as String)),
                        Text('₺${((d.data()['priceHistory'] as List?)?.isNotEmpty == true ? (d.data()['priceHistory'][0]['price'] ?? 0) : 0)}'),
                      ]),
                    ),
                  ))
              .toList(),
        );
      },
    );
  }
}

class _Banners extends StatelessWidget {
  const _Banners();
  @override
  Widget build(BuildContext context) => const Padding(
        padding: EdgeInsets.all(24),
        child: ProtoCard(child: Text('Banner yönetimi yüzeyi hazır.')),
      );
}

class _Categories extends StatelessWidget {
  const _Categories();
  @override
  Widget build(BuildContext context) => const Padding(
        padding: EdgeInsets.all(24),
        child: ProtoCard(child: Text('Kategori yönetimi yüzeyi hazır.')),
      );
}

class _Users extends StatelessWidget {
  const _Users();
  @override
  Widget build(BuildContext context) => const Padding(
        padding: EdgeInsets.all(24),
        child: ProtoCard(child: Text('Kullanıcı yönetimi yüzeyi hazır.')),
      );
}

class _Notifications extends StatelessWidget {
  const _Notifications();

  @override
  Widget build(BuildContext context) {
    final titleCtrl = TextEditingController();
    final bodyCtrl = TextEditingController();
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        TextField(controller: titleCtrl, decoration: const InputDecoration(labelText: 'Başlık')),
        const SizedBox(height: 10),
        TextField(controller: bodyCtrl, decoration: const InputDecoration(labelText: 'Mesaj')),
        const SizedBox(height: 12),
        FilledButton(
          onPressed: () {},
          style: FilledButton.styleFrom(backgroundColor: ProtoColors.tan, foregroundColor: ProtoColors.bgPrimary),
          child: const Text('Bildirim Gönder'),
        )
      ],
    );
  }
}
