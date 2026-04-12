import 'package:flutter/material.dart';

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
      body: SafeArea(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              decoration: const BoxDecoration(
                gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [ProtoColors.bgSecondary, ProtoColors.bgPrimary]),
                border: Border(bottom: BorderSide(color: ProtoColors.border)),
              ),
              child: Row(children: [
                const Expanded(child: Text('⚙ Admin Panel', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800))),
                InkWell(
                  onTap: () => Navigator.pop(context),
                  child: Container(width: 36, height: 36, decoration: protoSurface(radius: 18), alignment: Alignment.center, child: const Icon(Icons.close, color: ProtoColors.textSecondary)),
                )
              ]),
            ),
            Container(
              decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: ProtoColors.border))),
              child: TabBar(
                controller: _tc,
                isScrollable: true,
                indicatorColor: ProtoColors.tan,
                labelColor: ProtoColors.tan,
                unselectedLabelColor: ProtoColors.textSubtle,
                labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
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
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: TabBarView(
                  controller: _tc,
                  children: const [_Dashboard(), _Products(), _Banners(), _Categories(), _Users(), _Notifications()],
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}

class _Dashboard extends StatelessWidget {
  const _Dashboard();

  @override
  Widget build(BuildContext context) {
    return ListView(children: [
      GridView.count(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        children: const [
          _Stat('🏷', '6', 'Toplam Ürün', '+12%', true),
          _Stat('👥', '1,247', 'Aktif Kullanıcı', '+8%', true),
          _Stat('📈', '482', 'Bu Hafta Eklenen', '+23%', true),
          _Stat('🔔', '89', 'Aktif Alarm', '-5%', false),
        ],
      ),
      const SizedBox(height: 24),
      const _AdminTable(rows: [('📻 Bluetooth Hoparlör', '₺899', 'Elektronik', 'Aktif'), ('💪 Protein Tozu', '₺749', 'Gıda', 'Aktif'), ('🍳 Airfryer', '₺2.599', 'Ev', 'Beklemede')]),
    ]);
  }
}

class _Products extends StatelessWidget {
  const _Products();

  @override
  Widget build(BuildContext context) {
    return ListView(children: const [
      _SectionTitle('Ürün Yönetimi', 'Yeni Ürün'),
      _InlineCard(
        child: Column(children: [
          Row(children: [Expanded(child: _Input('Ürün Adı', 'Ürün adı girin')), SizedBox(width: 12), Expanded(child: _Input('Fiyat (TL)', '0'))]),
          Row(children: [Expanded(child: _Input('Kategori', 'Elektronik')), SizedBox(width: 12), Expanded(child: _Input('İkon', '📱'))]),
          SizedBox(height: 8),
          Row(children: [Expanded(child: _SmallPrimary('Kaydet')), SizedBox(width: 8), Expanded(child: _SmallSecondary('İptal'))]),
        ]),
      ),
      SizedBox(height: 16),
      _AdminTable(rows: [('📻 Bluetooth Hoparlör', '₺899', 'Elektronik', 'Aktif'), ('💪 Protein Tozu', '₺749', 'Gıda', 'Aktif')]),
    ]);
  }
}

class _Banners extends StatelessWidget {
  const _Banners();

  @override
  Widget build(BuildContext context) {
    return ListView(children: const [
      _SectionTitle('Banner Yönetimi', 'Yeni Banner'),
      _InlineCard(
        child: Column(children: [
          _Input('Başlık', 'Banner başlığı'),
          _Input('Açıklama', 'Kısa açıklama'),
          Row(children: [Expanded(child: _Input('Renk', 'Altın')), SizedBox(width: 12), Expanded(child: _Input('Etiket', '🔥 Fırsat'))]),
          SizedBox(height: 8),
          Row(children: [Expanded(child: _SmallPrimary('Kaydet')), SizedBox(width: 8), Expanded(child: _SmallSecondary('İptal'))]),
        ]),
      ),
      SizedBox(height: 16),
      _BannerItem('Haftanın Fırsatları', 'En çok düşen fiyatları keşfet', [Color(0xFF8B6914), Color(0xFFB8956A)]),
      _BannerItem('Doğrulanmış Düşüşler', 'Topluluk tarafından onaylananlar', [Color(0xFF4A6B5A), Color(0xFF6B8A7A)]),
    ]);
  }
}

class _Categories extends StatelessWidget {
  const _Categories();

  @override
  Widget build(BuildContext context) {
    return ListView(children: const [
      _SectionTitle('Kategori Yönetimi', 'Yeni Kategori'),
      _InlineCard(
        child: Column(children: [
          Row(children: [Expanded(child: _Input('Kategori Adı', 'Kategori adı')), SizedBox(width: 12), Expanded(child: _Input('İkon', 'fas fa-laptop'))]),
          SizedBox(height: 8),
          Row(children: [Expanded(child: _SmallPrimary('Kaydet')), SizedBox(width: 8), Expanded(child: _SmallSecondary('İptal'))]),
        ]),
      ),
      SizedBox(height: 16),
      _Pill('Elektronik'),
      _Pill('Gıda'),
      _Pill('Bakım'),
      _Pill('Ev'),
    ]);
  }
}

class _Users extends StatelessWidget {
  const _Users();

  @override
  Widget build(BuildContext context) {
    return const _AdminTable(headers: ['Kullanıcı', 'Level', 'XP', 'Durum', ''], rows: [('👤 Adem', '18', '750', 'Aktif'), ('👤 Fatih', '15', '520', 'Aktif'), ('👤 Zeynep', '12', '380', 'Beklemede')]);
  }
}

class _Notifications extends StatelessWidget {
  const _Notifications();

  @override
  Widget build(BuildContext context) {
    return ListView(children: const [
      Text('Bildirim Gönder', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
      SizedBox(height: 16),
      _InlineCard(
        child: Column(children: [
          _Input('Başlık', 'Bildirim başlığı'),
          _Input('Mesaj', 'Bildirim mesajı'),
          _Input('Hedef', 'Tüm Kullanıcılar'),
          SizedBox(height: 12),
          _PrimaryFull('Bildirim Gönder'),
        ]),
      )
    ]);
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.label, this.action);
  final String label;
  final String action;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(label, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
        Container(
          height: 36,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(gradient: const LinearGradient(colors: [ProtoColors.tan, ProtoColors.tanLight]), borderRadius: FRRadii.md),
          alignment: Alignment.center,
          child: Text(action, style: const TextStyle(color: ProtoColors.bgPrimary, fontSize: 12, fontWeight: FontWeight.w700)),
        )
      ]),
    );
  }
}

class _InlineCard extends StatelessWidget {
  const _InlineCard({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(padding: const EdgeInsets.all(16), decoration: protoSurface(radius: ProtoRadius.lg), child: child);
  }
}

class _Input extends StatelessWidget {
  const _Input(this.label, this.placeholder);
  final String label;
  final String placeholder;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: const TextStyle(fontSize: 12, color: ProtoColors.textSecondary, fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        Container(height: 44, padding: const EdgeInsets.symmetric(horizontal: 12), decoration: BoxDecoration(color: ProtoColors.surface, borderRadius: FRRadii.md, border: Border.all(color: ProtoColors.border)), alignment: Alignment.centerLeft, child: Text(placeholder, style: const TextStyle(fontSize: 14, color: ProtoColors.textSubtle))),
      ]),
    );
  }
}

class _SmallPrimary extends StatelessWidget {
  const _SmallPrimary(this.t);
  final String t;

  @override
  Widget build(BuildContext context) {
    return Container(height: 40, decoration: BoxDecoration(gradient: const LinearGradient(colors: [ProtoColors.tan, ProtoColors.tanLight]), borderRadius: FRRadii.md), alignment: Alignment.center, child: Text(t, style: const TextStyle(color: ProtoColors.bgPrimary, fontWeight: FontWeight.w700)));
  }
}

class _SmallSecondary extends StatelessWidget {
  const _SmallSecondary(this.t);
  final String t;

  @override
  Widget build(BuildContext context) {
    return Container(height: 40, decoration: BoxDecoration(color: ProtoColors.surface, borderRadius: FRRadii.md, border: Border.all(color: ProtoColors.border)), alignment: Alignment.center, child: Text(t, style: const TextStyle(fontWeight: FontWeight.w700)));
  }
}

class _PrimaryFull extends StatelessWidget {
  const _PrimaryFull(this.t);
  final String t;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      decoration: BoxDecoration(gradient: const LinearGradient(colors: [ProtoColors.tan, ProtoColors.tanLight]), borderRadius: FRRadii.md),
      alignment: Alignment.center,
      child: Text(t, style: const TextStyle(color: ProtoColors.bgPrimary, fontWeight: FontWeight.w700)),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat(this.icon, this.value, this.label, this.change, this.up);
  final String icon;
  final String value;
  final String label;
  final String change;
  final bool up;

  @override
  Widget build(BuildContext context) {
    final color = up ? ProtoColors.success : ProtoColors.danger;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: protoSurface(radius: ProtoRadius.lg),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(width: 36, height: 36, alignment: Alignment.center, decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: FRRadii.md), child: Text(icon)),
        const SizedBox(height: 12),
        Text(value, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800)),
        Text(label, style: const TextStyle(fontSize: 11, color: ProtoColors.textSubtle)),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: FRRadii.sm),
          child: Text(change, style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.w600)),
        )
      ]),
    );
  }
}

class _AdminTable extends StatelessWidget {
  const _AdminTable({this.headers = const ['Ürün', 'Fiyat', 'Kategori', 'Durum', ''], required this.rows});
  final List<String> headers;
  final List<(String, String, String, String)> rows;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: protoSurface(radius: ProtoRadius.lg),
      child: Column(children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: const BoxDecoration(color: ProtoColors.surfaceAlt, borderRadius: BorderRadius.vertical(top: Radius.circular(14))),
          child: Row(children: headers.map((h) => Expanded(child: Text(h, style: const TextStyle(fontSize: 11, color: ProtoColors.textSubtle, fontWeight: FontWeight.w600)))).toList()),
        ),
        ...rows.map((r) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: ProtoColors.borderLight))),
              child: Row(children: [
                Expanded(flex: 2, child: Text(r.$1, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600))),
                Expanded(child: Text(r.$2, style: const TextStyle(fontSize: 14, color: ProtoColors.tan, fontWeight: FontWeight.w700))),
                Expanded(child: Text(r.$3, style: const TextStyle(fontSize: 12, color: ProtoColors.textSecondary))),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(color: r.$4 == 'Aktif' ? ProtoColors.success.withOpacity(0.12) : ProtoColors.warning.withOpacity(0.12), borderRadius: FRRadii.sm),
                    child: Text(r.$4, style: TextStyle(fontSize: 11, color: r.$4 == 'Aktif' ? ProtoColors.success : ProtoColors.warning, fontWeight: FontWeight.w600)),
                  ),
                ),
                const SizedBox(width: 8),
                Container(width: 28, height: 28, alignment: Alignment.center, decoration: BoxDecoration(color: ProtoColors.surfaceElevated, borderRadius: FRRadii.sm), child: const Icon(Icons.edit, size: 13, color: ProtoColors.textSubtle)),
              ]),
            ))
      ]),
    );
  }
}

class _BannerItem extends StatelessWidget {
  const _BannerItem(this.title, this.desc, this.colors);
  final String title;
  final String desc;
  final List<Color> colors;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: protoSurface(radius: ProtoRadius.lg),
      child: Row(children: [
        Container(width: 80, height: 50, decoration: BoxDecoration(borderRadius: FRRadii.md, gradient: LinearGradient(colors: colors)), alignment: Alignment.center, child: const Text('BANNER', style: TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.w700))),
        const SizedBox(width: 14),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)), Text(desc, style: const TextStyle(fontSize: 11, color: ProtoColors.textSubtle))])),
      ]),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill(this.t);
  final String t;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: protoSurface(radius: ProtoRadius.md),
      child: Text(t, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
    );
  }
}
