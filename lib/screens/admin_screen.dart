import 'package:flutter/material.dart';

import '../widgets/executive_ui.dart';

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  int tab = 0;
  final tabs = const ['Panel', 'Ürünler', 'Talepler', 'Fiyatlar', 'Raporlar', 'Banner', 'Kullanıcılar', 'Moderasyon', 'Ayarlar'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ExecColors.bg,
      body: SafeArea(
        child: Column(
          children: [
            _Header(onBack: () => Navigator.pop(context)),
            SizedBox(
              height: 44,
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
                scrollDirection: Axis.horizontal,
                itemCount: tabs.length,
                itemBuilder: (_, i) => InkWell(
                  onTap: () => setState(() => tab = i),
                  child: Container(
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 9),
                    decoration: BoxDecoration(
                      color: tab == i ? ExecColors.espresso : ExecColors.surface,
                      borderRadius: ExecRadii.pill,
                      border: Border.all(color: tab == i ? ExecColors.gold : ExecColors.bgDeep),
                    ),
                    child: Text(tabs[i], style: manrope(12, FontWeight.w700, color: tab == i ? ExecColors.gold : ExecColors.ink2)),
                  ),
                ),
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
                children: [_buildTab()],
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildTab() {
    switch (tab) {
      case 0:
        return Column(children: [_panelGrid(), const SizedBox(height: 14), _label('SON AKTİVİTE'), ..._rows(['iPhone 15 Pro Max · MediaMarkt|merve_k · 72.999 ₺ · 2 saat önce', 'Yeni kullanıcı kaydı|ayse_b · Kadıköy · 18 dakika önce'])]);
      case 1:
        return Column(children: _rows(['iPhone 15 Pro Max 256GB|3 fiyat · 12 doğrulama', 'Samsung QLED 55" Q80C|2 fiyat · 8 doğrulama', 'Kurukahveci M.E. 250g|8 fiyat · 34 doğrulama']));
      case 2:
        return Column(children: [_requestFilter(), const SizedBox(height: 10), ..._requests()]);
      case 3:
        return Column(children: _rows(['iPhone 15 Pro Max · MediaMarkt|merve_k · 72.999 ₺', 'Nike Air Force 1 · Sport Point|emre_s · 3.499 ₺']));
      case 4:
        return Column(children: _rows(['Şüpheli fiyat bildirimi|3 kullanıcı bildirdi · Samsung QLED · 12.000 ₺', 'Spam kullanıcı şüphesi|kullanıcı_x · 48 saatte 156 fiyat']));
      case 5:
        return Column(children: [_bannerForm(), const SizedBox(height: 10), ..._rows(['Haftanın Fırsatları|En çok düşen fiyatları keşfet', 'Doğrulanmış Düşüşler|Topluluk tarafından onaylananlar'])]);
      case 6:
        return Column(children: _rows(['merve_k|2.450 PT · Güven %96 · 84 katkı', 'emre_s|3.840 PT · Güven %94 · 127 katkı']));
      case 7:
        return Column(children: _rows(['Şüpheli fiyat bildirimi|3 kullanıcı bildirdi', 'Spam kullanıcı şüphesi|kullanıcı_x · 156 fiyat']));
      default:
        return _settingsForm();
    }
  }

  Widget _panelGrid() => GridView.count(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisCount: 2,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        children: const [
          _Stat('247', 'BUGÜN ONAY', '+18%'),
          _Stat('12', 'BEKLEYEN', 'acil'),
          _Stat('3.8K', 'AKTİF KULLANICI', '+4%'),
          _Stat('%94', 'GÜVEN SKORU', '+2'),
        ],
      );

  Widget _label(String t) => Align(alignment: Alignment.centerLeft, child: Text(t, style: manrope(10, FontWeight.w800, color: ExecColors.ink3, letterSpacing: 2.0)));

  List<Widget> _rows(List<String> data) => data
      .map((e) {
        final p = e.split('|');
        return Container(
          margin: const EdgeInsets.only(top: 10),
          padding: const EdgeInsets.all(12),
          decoration: execCard(radius: 18),
          child: Row(children: [
            Container(width: 34, height: 34, decoration: BoxDecoration(color: ExecColors.bgSoft, borderRadius: BorderRadius.circular(12)), child: const Icon(Icons.sell_outlined, size: 16, color: ExecColors.goldDeep)),
            const SizedBox(width: 9),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(p.first, style: manrope(13, FontWeight.w800)), Text(p.last, style: manrope(11, FontWeight.w600, color: ExecColors.ink3))])),
            Row(children: [_act(Icons.check, const Color(0xFFE4F0DE), ExecColors.success), const SizedBox(width: 6), _act(Icons.close, const Color(0xFFF5E1DC), ExecColors.danger)])
          ]),
        );
      })
      .toList();

  Widget _requestFilter() => Container(
      padding: const EdgeInsets.all(4),
      decoration: execCard(radius: 14),
      child: Row(children: const [Expanded(child: _MiniFilter('Bekleyen 7', true)), Expanded(child: _MiniFilter('Onaylanan 142', false)), Expanded(child: _MiniFilter('Reddedilen 23', false))]));

  List<Widget> _requests() => [
        _request('merve_k', 'Samsung Galaxy S24 Ultra 512GB', 'Teknoloji · Telefon', 'Resmi Samsung Türkiye sitesi bağlantısı', true),
        _request('emre_s', 'Dyson V12 Detect Slim', 'Ev · Temizlik', 'Dyson TR resmi ürün sayfası', false),
      ];

  Widget _request(String user, String urun, String kat, String aciklama, bool wait) => Container(
        margin: const EdgeInsets.only(top: 10),
        padding: const EdgeInsets.all(12),
        decoration: execCard(radius: 18),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [CircleAvatar(radius: 14, backgroundColor: ExecColors.gold, child: Text(user[0].toUpperCase(), style: manrope(11, FontWeight.w800, color: ExecColors.espresso))), const SizedBox(width: 8), Expanded(child: Text(user, style: manrope(13, FontWeight.w800))), Text(wait ? '● Bekliyor' : '● Onaylı', style: manrope(10, FontWeight.w800, color: wait ? ExecColors.danger : ExecColors.success))]),
          const SizedBox(height: 8),
          _kv('Ürün', urun),
          _kv('Kategori', kat),
          _kv('Açıklama', aciklama),
          const SizedBox(height: 8),
          Row(children: [Expanded(child: _btn('Onayla & Kataloğa Ekle', true)), const SizedBox(width: 8), Expanded(child: _btn('Reddet', false))]),
        ]),
      );

  Widget _kv(String k, String v) => Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [SizedBox(width: 62, child: Text(k, style: manrope(11, FontWeight.w700, color: ExecColors.ink3))), Expanded(child: Text(v, style: manrope(11, FontWeight.w700, color: ExecColors.ink2)))]),
      );

  Widget _bannerForm() => Container(
        padding: const EdgeInsets.all(14),
        decoration: execCard(radius: 20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Banner Yönetimi', style: manrope(14, FontWeight.w800)),
          const SizedBox(height: 10),
          Row(children: [Expanded(child: _input('Başlık')), const SizedBox(width: 8), Expanded(child: _input('Etiket'))]),
          _input('Açıklama'),
          Row(children: [Expanded(child: _btn('Kaydet', true)), const SizedBox(width: 8), Expanded(child: _btn('İptal', false))]),
        ]),
      );

  Widget _settingsForm() => Container(
        padding: const EdgeInsets.all(14),
        decoration: execCard(radius: 20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Admin Ayarları', style: manrope(14, FontWeight.w800)),
          const SizedBox(height: 10),
          _input('Günlük onay limiti'),
          _input('Auto-moderasyon eşiği'),
          _input('Bildirim toplu gönderim saati'),
          _btn('Kaydet', true),
        ]),
      );

  Widget _input(String label) => Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 10),
      height: 42,
      decoration: BoxDecoration(color: ExecColors.surface2, borderRadius: BorderRadius.circular(12), border: Border.all(color: ExecColors.bgDeep)),
      child: Align(alignment: Alignment.centerLeft, child: Text(label, style: manrope(12, FontWeight.w700, color: ExecColors.ink4))));

  Widget _btn(String t, bool p) => Container(
      height: 38,
      decoration: BoxDecoration(color: p ? ExecColors.espresso : ExecColors.surface2, borderRadius: BorderRadius.circular(12), border: Border.all(color: p ? ExecColors.espresso : ExecColors.bgDeep)),
      child: Center(child: Text(t, style: manrope(11, FontWeight.w800, color: p ? ExecColors.gold : ExecColors.ink2))));

  static Widget _act(IconData i, Color bg, Color fg) => Container(width: 28, height: 28, decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(10)), child: Icon(i, size: 15, color: fg));
}

class _Header extends StatelessWidget {
  const _Header({required this.onBack});
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        InkWell(onTap: onBack, child: const Icon(Icons.chevron_left, color: ExecColors.ink2)),
        RichText(text: TextSpan(text: 'Admin ', style: fraunces(44, FontWeight.w700), children: [TextSpan(text: 'Konsolu', style: fraunces(44, FontWeight.w400, color: ExecColors.ink3, style: FontStyle.italic))])),
        const SizedBox(height: 8),
        Text('FİYATRADAR KONTROL MERKEZİ', style: manrope(10, FontWeight.w800, color: ExecColors.goldDeep, letterSpacing: 2.2)),
      ]),
    );
  }
}

class _MiniFilter extends StatelessWidget {
  const _MiniFilter(this.t, this.a);
  final String t;
  final bool a;

  @override
  Widget build(BuildContext context) => Container(
      height: 34,
      margin: const EdgeInsets.symmetric(horizontal: 2),
      decoration: BoxDecoration(color: a ? ExecColors.espresso : Colors.transparent, borderRadius: BorderRadius.circular(10)),
      child: Center(child: Text(t, style: manrope(10, FontWeight.w800, color: a ? ExecColors.gold : ExecColors.ink3), textAlign: TextAlign.center)));
}

class _Stat extends StatelessWidget {
  const _Stat(this.v, this.k, this.e);
  final String v;
  final String k;
  final String e;

  @override
  Widget build(BuildContext context) => Container(
        decoration: execCard(radius: 18),
        padding: const EdgeInsets.all(12),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(k, style: manrope(10, FontWeight.w800, color: ExecColors.ink3, letterSpacing: 1.4)),
          const Spacer(),
          RichText(text: TextSpan(text: v, style: fraunces(30, FontWeight.w700), children: [TextSpan(text: '  $e', style: manrope(11, FontWeight.w800, color: ExecColors.goldDeep))])),
        ]),
      );
}
