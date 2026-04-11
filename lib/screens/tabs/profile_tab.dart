import 'package:flutter/material.dart';

import '../../state/app_state.dart';
import '../../widgets/prototype_ui.dart';
import '../admin_screen.dart';
import '../profile/alerts_screen.dart';
import '../profile/favorites_screen.dart';
import '../profile/history_screen.dart';
import '../settings_screen.dart';

class ProfileTab extends StatelessWidget {
  const ProfileTab({super.key});

  @override
  Widget build(BuildContext context) {
    final state = AppStateScope.of(context);
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(24, 10, 24, 90),
        children: [
          Row(children: [
            const Expanded(child: Text('Profil', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800))),
            IconButton(onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminScreen())), icon: const Icon(Icons.settings, color: ProtoColors.textSecondary))
          ]),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [ProtoColors.bgSecondary, ProtoColors.bgPrimary]),
              borderRadius: BorderRadius.circular(ProtoRadius.xl),
              border: Border.all(color: ProtoColors.border),
            ),
            child: Column(children: [
              Container(
                width: 96,
                height: 96,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: ProtoColors.tan.withOpacity(0.4), width: 2),
                  gradient: LinearGradient(colors: [ProtoColors.tan.withOpacity(0.2), ProtoColors.tan.withOpacity(0.04)]),
                ),
                alignment: Alignment.center,
                child: const Text('FK', style: TextStyle(fontSize: 30, color: ProtoColors.tan, fontWeight: FontWeight.w800)),
              ),
              const SizedBox(height: 12),
              Text(state.displayName, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: ProtoColors.tan.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(99),
                  border: Border.all(color: ProtoColors.tan.withOpacity(0.25)),
                ),
                child: const Text('👑 Level 18 • Elite', style: TextStyle(color: ProtoColors.tan, fontWeight: FontWeight.w700, fontSize: 12)),
              ),
              const SizedBox(height: 16),
              Row(children: [
                _stat('482', 'Fiyat'),
                _stat('137', 'Doğrulama'),
                _stat('${state.points}', 'Puan'),
              ])
            ]),
          ),
          const SizedBox(height: 12),
          const ProtoCard(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Level 19 İlerlemesi', style: TextStyle(color: ProtoColors.textSecondary, fontSize: 12)),
            SizedBox(height: 8),
            LinearProgressIndicator(value: 0.75, minHeight: 8, color: ProtoColors.tan, backgroundColor: ProtoColors.surfaceAlt),
          ])),
          const SizedBox(height: 12),
          ...[
            ('Favoriler', const FavoritesScreen()),
            ('Fiyat Alarmları', const AlertsScreen()),
            ('Katkı Geçmişi', const HistoryScreen()),
            ('Ayarlar', const SettingsScreen()),
            ('Yönetim Paneli', const AdminScreen()),
          ].map((e) => Container(
                margin: const EdgeInsets.only(bottom: 10),
                child: InkWell(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => e.$2),
                  ),
                  borderRadius: BorderRadius.circular(ProtoRadius.xl),
                  child: ProtoCard(
                    child: Row(children: [
                      Container(width: 36, height: 36, decoration: BoxDecoration(color: ProtoColors.surfaceAlt, borderRadius: BorderRadius.circular(10)), child: const Icon(Icons.chevron_right, color: ProtoColors.tan)),
                      const SizedBox(width: 12),
                      Expanded(child: Text(e.$1, style: const TextStyle(fontWeight: FontWeight.w600))),
                      const Icon(Icons.chevron_right, color: ProtoColors.textSubtle)
                    ]),
                  ),
                ),
              )),
        ],
      ),
    );
  }

  Widget _stat(String v, String l) => Expanded(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 4),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: protoSurface(radius: ProtoRadius.lg),
          child: Column(children: [
            Text(v, style: const TextStyle(color: ProtoColors.tan, fontSize: 20, fontWeight: FontWeight.w800)),
            Text(l, style: const TextStyle(color: ProtoColors.textSubtle, fontSize: 10)),
          ]),
        ),
      );
}
