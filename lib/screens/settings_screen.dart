import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../core/state/user_state.dart';
import '../core/theme/app_colors.dart';
import '../widgets/app_widgets.dart';
import 'admin_screen.dart';
import 'faq_screen.dart';
import 'update_history_screen.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final enabled = ref.watch(isNotificationEnabledProvider);
    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      body: Column(
        children: [
          const StatusBar(),
          const AppTopBar(title: 'Ayarlar'),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
              children: [
                _item('Bildirimler', FontAwesomeIcons.bell, trailing: Switch(value: enabled, onChanged: (v) => ref.read(isNotificationEnabledProvider.notifier).state = v)),
                _item('Sıkça Sorulan Sorular', FontAwesomeIcons.circleQuestion, onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const FaqScreen()))),
                _item('Güncelleme Geçmişi', FontAwesomeIcons.clockRotateLeft, onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const UpdateHistoryScreen()))),
                _item('Admin Panel', FontAwesomeIcons.chartLine, onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminScreen()))),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _item(String title, IconData icon, {Widget? trailing, VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(AppColors.radiusLg), border: Border.all(color: AppColors.border)),
        child: Row(children: [
          FaIcon(icon, size: 14, color: AppColors.tan),
          const SizedBox(width: 12),
          Expanded(child: Text(title, style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.textPrimary))),
          trailing ?? const FaIcon(FontAwesomeIcons.chevronRight, size: 12, color: AppColors.textSubtle),
        ]),
      ),
    );
  }
}

class SimpleScreen extends StatelessWidget {
  const SimpleScreen({super.key, required this.title});
  final String title;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      body: Column(children: [
        const StatusBar(),
        AppTopBar(title: title),
        const Expanded(child: SizedBox()),
      ]),
    );
  }
}
