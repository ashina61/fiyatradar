import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../core/state/user_state.dart';
import '../core/theme/app_colors.dart';
import '../widgets/app_widgets.dart';
import 'leaderboard_screen.dart';
import 'notifications_screen.dart';
import 'settings_screen.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final level = ref.watch(userLevelProvider);

    return Column(children: [
      const StatusBar(),
      AppTopBar(
        title: 'Profil',
        trailing: InkWell(
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen())),
          child: const FaIcon(FontAwesomeIcons.gear, color: AppColors.textSecondary, size: 18),
        ),
      ),
      Expanded(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
          children: [
            Container(
              padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
              decoration: BoxDecoration(
                gradient: const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [AppColors.bgSecondary, Colors.transparent]),
                borderRadius: BorderRadius.circular(AppColors.radiusXl),
              ),
              child: Column(children: [
                const CircleAvatar(radius: 48, backgroundColor: AppColors.surfaceAlt, child: Text('👤', style: TextStyle(fontSize: 40))),
                const SizedBox(height: 16),
                const Text('Mehmet Yılmaz', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
                Text('Level $level', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.tan)),
              ]),
            ),
            const SizedBox(height: 16),
            _menuItem(context, FontAwesomeIcons.bell, 'Bildirimler', () => Navigator.push(context, MaterialPageRoute(builder: (_) => const NotificationsScreen()))),
            _menuItem(context, FontAwesomeIcons.trophy, 'Liderlik Tablosu', () => Navigator.push(context, MaterialPageRoute(builder: (_) => const LeaderboardScreen()))),
          ],
        ),
      ),
    ]);
  }

  Widget _menuItem(BuildContext context, IconData icon, String label, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(AppColors.radiusLg), border: Border.all(color: AppColors.border)),
        child: Row(children: [
          FaIcon(icon, color: AppColors.tan, size: 14),
          const SizedBox(width: 10),
          Expanded(child: Text(label, style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600))),
          const FaIcon(FontAwesomeIcons.chevronRight, color: AppColors.textSubtle, size: 12),
        ]),
      ),
    );
  }
}
