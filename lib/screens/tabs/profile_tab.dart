import 'package:flutter/material.dart';

import '../../widgets/prototype_ui.dart';
import '../admin_screen.dart';

class ProfileTab extends StatelessWidget {
  const ProfileTab({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.only(bottom: 95),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 12),
            child: Row(children: [
              const Icon(Icons.arrow_back, size: 20),
              const SizedBox(width: 12),
              const Expanded(child: Text('Profil', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800))),
              InkWell(
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminScreen())),
                child: const Icon(Icons.settings, color: ProtoColors.textSecondary),
              )
            ]),
          ),
          Container(
            padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
            decoration: BoxDecoration(
              gradient: const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [ProtoColors.bgSecondary, ProtoColors.bgPrimary]),
              borderRadius: FRRadii.xl,
            ),
            child: Column(children: [
              Container(
                width: 96,
                height: 96,
                decoration: BoxDecoration(
                  borderRadius: FRRadii.pill,
                  gradient: LinearGradient(colors: [ProtoColors.tan.withOpacity(0.2), ProtoColors.tan.withOpacity(0.05)]),
                  border: Border.all(color: ProtoColors.tan.withOpacity(0.3), width: 2),
                ),
                alignment: Alignment.center,
                child: const Text('FK', style: TextStyle(fontSize: 36, color: ProtoColors.tan, fontWeight: FontWeight.w800)),
              ),
              const SizedBox(height: 16),
              const Text('Adem', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [ProtoColors.tan.withOpacity(0.15), ProtoColors.tan.withOpacity(0.05)]),
                  border: Border.all(color: ProtoColors.tan.withOpacity(0.2)),
                  borderRadius: FRRadii.pill,
                ),
                child: const Text('👑 Level 18 • Elite', style: TextStyle(fontSize: 12, color: ProtoColors.tan, fontWeight: FontWeight.w700)),
              ),
              const SizedBox(height: 20),
              Row(children: const [_Stat('482', 'Fiyat'), _Stat('137', 'Doğrulama'), _Stat('96', 'Yorum')]),
            ]),
          ),
          Container(
            margin: const EdgeInsets.fromLTRB(24, 16, 24, 24),
            padding: const EdgeInsets.all(16),
            decoration: protoSurface(),
            child: const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Level 19 İlerlemesi', style: TextStyle(fontSize: 13, color: ProtoColors.textSecondary, fontWeight: FontWeight.w600)), Text('750 / 1000 XP', style: TextStyle(fontSize: 12, color: ProtoColors.tan, fontWeight: FontWeight.w700))]),
              SizedBox(height: 10),
              ClipRRect(borderRadius: FRRadii.pill, child: LinearProgressIndicator(value: 0.75, minHeight: 8, color: ProtoColors.tan, backgroundColor: ProtoColors.surfaceAlt)),
              SizedBox(height: 8),
              Text('3 katkı daha yaparsan Level 19 olacaksın!', style: TextStyle(fontSize: 10, color: ProtoColors.textSubtle), textAlign: TextAlign.center),
            ]),
          ),
          Container(
            margin: const EdgeInsets.fromLTRB(24, 0, 24, 16),
            decoration: protoSurface(),
            child: const Column(children: [
              _ToggleRow(Icons.notifications, 'Bildirimler', true),
              _ToggleRow(Icons.location_on, 'Konum', false),
              _ToggleRow(Icons.dark_mode, 'Karanlık Mod', true, last: true),
            ]),
          ),
          Container(
            margin: const EdgeInsets.fromLTRB(24, 0, 24, 24),
            decoration: protoSurface(),
            child: const Column(children: [
              _Setting(Icons.info, 'Hakkında'),
              _Setting(Icons.shield, 'Gizlilik'),
              _Setting(Icons.question_mark, 'FAQ'),
              _Setting(Icons.history, 'Güncelleme Geçmişi', last: true),
            ]),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
            child: SizedBox(
              height: 52,
              child: OutlinedButton.icon(
                onPressed: () {},
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: ProtoColors.danger.withOpacity(0.3)),
                  backgroundColor: ProtoColors.danger.withOpacity(0.15),
                  shape: RoundedRectangleBorder(borderRadius: FRRadii.lg),
                ),
                icon: const Icon(Icons.logout, color: ProtoColors.danger),
                label: const Text('Çıkış Yap', style: TextStyle(color: ProtoColors.danger, fontWeight: FontWeight.w700)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat(this.value, this.label);
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 5),
        padding: const EdgeInsets.all(14),
        decoration: protoSurface(radius: ProtoRadius.lg),
        child: Column(children: [
          Text(value, style: const TextStyle(fontSize: 22, color: ProtoColors.tan, fontWeight: FontWeight.w800)),
          const SizedBox(height: 4),
          Text(label.toUpperCase(), style: const TextStyle(fontSize: 10, color: ProtoColors.textSubtle, letterSpacing: 0.3)),
        ]),
      ),
    );
  }
}

class _ToggleRow extends StatelessWidget {
  const _ToggleRow(this.icon, this.label, this.active, {this.last = false});
  final IconData icon;
  final String label;
  final bool active;
  final bool last;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(border: last ? null : const Border(bottom: BorderSide(color: ProtoColors.borderLight))),
      child: Row(children: [
        Container(width: 36, height: 36, decoration: BoxDecoration(color: ProtoColors.surfaceAlt, borderRadius: FRRadii.md, border: Border.all(color: ProtoColors.border)), child: Icon(icon, color: ProtoColors.tan, size: 16)),
        const SizedBox(width: 12),
        Expanded(child: Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600))),
        Container(
          width: 48,
          height: 26,
          decoration: BoxDecoration(color: active ? ProtoColors.tan : ProtoColors.surfaceAlt, borderRadius: FRRadii.pill, border: Border.all(color: active ? ProtoColors.tan : ProtoColors.border)),
          child: Align(
            alignment: active ? Alignment.centerRight : Alignment.centerLeft,
            child: Container(margin: const EdgeInsets.all(2), width: 20, height: 20, decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle)),
          ),
        )
      ]),
    );
  }
}

class _Setting extends StatelessWidget {
  const _Setting(this.icon, this.label, {this.last = false});
  final IconData icon;
  final String label;
  final bool last;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(border: last ? null : const Border(bottom: BorderSide(color: ProtoColors.borderLight))),
      child: Row(children: [
        Container(width: 36, height: 36, decoration: BoxDecoration(color: ProtoColors.surfaceAlt, borderRadius: FRRadii.md, border: Border.all(color: ProtoColors.border)), child: Icon(icon, color: ProtoColors.tan, size: 16)),
        const SizedBox(width: 12),
        Expanded(child: Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600))),
        const Icon(Icons.chevron_right, color: ProtoColors.textSubtle),
      ]),
    );
  }
}
