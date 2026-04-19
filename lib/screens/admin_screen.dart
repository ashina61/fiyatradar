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
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [InkWell(onTap: () => Navigator.pop(context), child: const Icon(Icons.chevron_left_rounded, color: ExecColors.ink2)), RichText(text: TextSpan(text: 'Admin ', style: fraunces(44, FontWeight.w700), children: [TextSpan(text: 'Konsolu', style: fraunces(44, FontWeight.w400, color: ExecColors.ink3, style: FontStyle.italic))])), const SizedBox(height: 8), Text('FİYATRADAR KONTROL MERKEZİ', style: manrope(10, FontWeight.w800, color: ExecColors.goldDeep, letterSpacing: 2.2))]),
            ),
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
                    decoration: BoxDecoration(color: tab == i ? ExecColors.espresso : ExecColors.surface, borderRadius: ExecRadii.pill, border: Border.all(color: tab == i ? ExecColors.gold : ExecColors.bgDeep)),
                    child: Text(tabs[i], style: manrope(12, FontWeight.w700, color: tab == i ? ExecColors.gold : ExecColors.ink2)),
                  ),
                ),
              ),
            ),
            Expanded(child: ListView(padding: const EdgeInsets.fromLTRB(20, 18, 20, 24), children: [_buildTab()])),
          ],
        ),
      ),
    );
  }

  Widget _buildTab() {
    if (tab == 0) {
      return Column(children: [_panelGrid(), const SizedBox(height: 14), _label('SON AKTİVİTE'), ..._rows(['iPhone 15 Pro Max · MediaMarkt|merve_k · 72.999 ₺ · 2 saat önce', 'Yeni kullanıcı kaydı|ayse_b · Kadıköy · 18 dakika önce'])]);
    }
    if (tab == 1) return Column(children: _rows(['iPhone 15 Pro Max 256GB|3 fiyat · 12 doğrulama', 'Samsung QLED 55" Q80C|2 fiyat · 8 doğrulama', 'Kurukahveci M.E. 250g|8 fiyat · 34 doğrulama']));
    if (tab == 2) return Column(children: _rows(['Samsung Galaxy S24 Ultra 512GB|Bekleyen talep', 'Dyson V15 Detect Absolute|Bekleyen talep', 'Lavazza Qualità Rossa 1kg|Bekleyen talep']));
    if (tab == 3) return Column(children: _rows(['iPhone 15 Pro Max · MediaMarkt|merve_k · 72.999 ₺', 'Nike Air Force 1 · Sport Point|emre_s · 3.499 ₺']));
    if (tab == 4) return Column(children: _rows(['Şüpheli fiyat bildirimi|3 kullanıcı bildirdi · Samsung QLED', 'Spam kullanıcı şüphesi|kullanıcı_x · 48 saatte 156 fiyat']));
    if (tab == 5) return Column(children: _rows(['Ana banner aktif|Haftanın fırsatları', 'Kampanya kartı|Doğrulanmış düşüşler']));
    if (tab == 6) return Column(children: _rows(['merve_k|2.450 PT · Güven %96 · 84 katkı', 'emre_s|3.840 PT · Güven %94 · 127 katkı']));
    if (tab == 7) return Column(children: _rows(['Şüpheli fiyat bildirimi|3 kullanıcı raporladı', 'Spam kullanıcı|İnceleme bekliyor']));
    return Column(children: _rows(['Günlük onay limiti|500', 'Toplu bildirim saati|19:00']));
  }

  Widget _panelGrid() => GridView.count(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisCount: 2,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        children: const [_Stat('247', 'BUGÜN ONAY', '+18%'), _Stat('12', 'BEKLEYEN', 'acil'), _Stat('3.8K', 'AKTİF KULLANICI', '+4%'), _Stat('%94', 'GÜVEN SKORU', '+2')],
      );

  Widget _label(String t) => Align(alignment: Alignment.centerLeft, child: Text(t, style: manrope(10, FontWeight.w800, color: ExecColors.ink3, letterSpacing: 2.0)));

  List<Widget> _rows(List<String> data) => data
      .map((e) {
        final p = e.split('|');
        return Container(
          margin: const EdgeInsets.only(top: 10),
          padding: const EdgeInsets.all(12),
          decoration: execCard(radius: 18),
          child: Row(children: [Container(width: 34, height: 34, decoration: BoxDecoration(color: ExecColors.bgSoft, borderRadius: BorderRadius.circular(12)), child: const Icon(Icons.sell_outlined, size: 16, color: ExecColors.goldDeep)), const SizedBox(width: 9), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(p.first, style: manrope(13, FontWeight.w800)), Text(p.last, style: manrope(11, FontWeight.w600, color: ExecColors.ink3))])), Row(children: [_act(Icons.check, const Color(0xFFE4F0DE), ExecColors.success), const SizedBox(width: 6), _act(Icons.close, const Color(0xFFF5E1DC), ExecColors.danger)])]),
        );
      })
      .toList();

  static Widget _act(IconData i, Color bg, Color fg) => Container(width: 28, height: 28, decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(10)), child: Icon(i, size: 15, color: fg));
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
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(k, style: manrope(10, FontWeight.w800, color: ExecColors.ink3, letterSpacing: 1.4)), const Spacer(), RichText(text: TextSpan(text: v, style: fraunces(30, FontWeight.w700), children: [TextSpan(text: '  $e', style: manrope(11, FontWeight.w800, color: ExecColors.goldDeep))]))]),
      );
}
