import 'package:flutter/material.dart';

import '../../state/app_state.dart';
import '../../widgets/executive_ui.dart';
import '../admin_screen.dart';

class ProfileTab extends StatelessWidget {
  const ProfileTab({super.key});

  @override
  Widget build(BuildContext context) {
    final state = AppStateScope.of(context);

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 120),
        children: [
          Text('KİMLİK · GÜVEN · KATKI', style: manrope(10, FontWeight.w800, color: ExecColors.goldDeep, letterSpacing: 2.2)),
          const SizedBox(height: 6),
          Text('Profil', style: fraunces(44, FontWeight.w700)),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(borderRadius: ExecRadii.xl, gradient: const LinearGradient(colors: [ExecColors.espresso2, ExecColors.espresso])),
            child: Column(children: [Container(width: 92, height: 92, decoration: BoxDecoration(color: const Color(0x26C9A063), borderRadius: BorderRadius.circular(30), border: Border.all(color: const Color(0x66C9A063))), alignment: Alignment.center, child: Text((state.displayName.isEmpty ? 'F' : state.displayName[0].toUpperCase()), style: fraunces(40, FontWeight.w700, color: ExecColors.gold))), const SizedBox(height: 10), Text(state.displayName, style: fraunces(30, FontWeight.w600, color: ExecColors.onDark)), Text(state.username, style: manrope(13, FontWeight.w700, color: const Color(0xFFC9BCA6))), const SizedBox(height: 12), Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6), decoration: BoxDecoration(color: const Color(0x26C9A063), borderRadius: ExecRadii.pill), child: Text('Elit Radar · ${state.points} PT', style: manrope(11, FontWeight.w800, color: ExecColors.gold)))]),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: execCard(radius: 22),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Rütbe ilerlemesi', style: manrope(12, FontWeight.w700, color: ExecColors.ink3)), Text('${state.points % 1000}/1000', style: manrope(12, FontWeight.w800, color: ExecColors.goldDeep))]), const SizedBox(height: 10), ClipRRect(borderRadius: ExecRadii.pill, child: LinearProgressIndicator(value: (state.points % 1000) / 1000, minHeight: 8, color: ExecColors.gold, backgroundColor: ExecColors.bgDeep))]),
          ),
          const SizedBox(height: 12),
          _group([_row(Icons.favorite_rounded, 'Favorilerim', '12 ürün takipte'), _row(Icons.notifications_active_rounded, 'Bildirim Tercihleri', state.pushNotificationsEnabled ? 'Açık' : 'Kapalı'), _row(Icons.place_rounded, 'Konum Ayarları', 'Kadıköy, İstanbul')]),
          const SizedBox(height: 12),
          _group([_row(Icons.shield_outlined, 'Güvenlik', state.twoFactorEnabled ? '2FA Açık' : '2FA Kapalı'), _row(Icons.history, 'Katkı Geçmişim', 'Son 30 gün'), _row(Icons.stars_rounded, 'Rozetler', '14 / 42 tamamlandı')]),
          const SizedBox(height: 8),
          OutlinedButton.icon(onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminScreen())), style: OutlinedButton.styleFrom(side: const BorderSide(color: ExecColors.bgDeep), shape: RoundedRectangleBorder(borderRadius: ExecRadii.pill), padding: const EdgeInsets.symmetric(vertical: 14)), icon: const Icon(Icons.admin_panel_settings_outlined, color: ExecColors.ink2), label: Text('Admin Konsolu', style: manrope(14, FontWeight.w800, color: ExecColors.ink2))),
        ],
      ),
    );
  }

  Widget _group(List<Widget> children) => Container(decoration: execCard(radius: 20), child: Column(children: children));

  Widget _row(IconData icon, String title, String subtitle) => Container(
        padding: const EdgeInsets.all(14),
        decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: ExecColors.bgDeep))),
        child: Row(children: [Container(width: 36, height: 36, decoration: BoxDecoration(color: ExecColors.bgSoft, borderRadius: BorderRadius.circular(12)), child: Icon(icon, color: ExecColors.goldDeep, size: 18)), const SizedBox(width: 10), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: manrope(13, FontWeight.w800)), Text(subtitle, style: manrope(11, FontWeight.w600, color: ExecColors.ink3))])), const Icon(Icons.chevron_right, color: ExecColors.ink4)]),
      );
}
