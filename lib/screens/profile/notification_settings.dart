import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/profile_provider.dart';

class NotificationSettingsScreen extends ConsumerWidget {
  const NotificationSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileState = ref.watch(profileProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F3F0),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFDFBF9).withOpacity(0.95),
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Color(0xFF8B4D22)),
        title: const Text('Bildirimler', style: TextStyle(color: Color(0xFF2D241E), fontSize: 17, fontWeight: FontWeight.w600)),
      ),
      body: profileState.when(
        loading: () => const Center(child: CircularProgressIndicator(color: Color(0xFF8B4D22))),
        error: (error, _) => Center(child: Text('Hata: $error')),
        data: (user) {
          if (user == null) return const Center(child: Text('Profil bulunamadı.'));

          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
            children: [
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0x148B4D22)),
                ),
                child: Column(
                  children: [
                    _switchTile(
                      title: 'Fiyat Alarmı Bildirimleri',
                      subtitle: 'Takip ettiğin ürün düştüğünde uyar.',
                      value: user.alarmNotifications,
                      onChanged: (val) => ref.read(profileProvider.notifier).updateProfile(user.copyWith(alarmNotifications: val)),
                    ),
                    _switchTile(
                      title: 'Kampanya Bildirimleri',
                      subtitle: 'A101, BİM vb. haftalık indirimleri.',
                      value: user.campaignNotifications,
                      onChanged: (val) => ref.read(profileProvider.notifier).updateProfile(user.copyWith(campaignNotifications: val)),
                    ),
                    _switchTile(
                      title: 'Rozet ve Puan Bildirimleri',
                      subtitle: 'Liderlik tablosunda yükseldiğinde uyar.',
                      value: user.badgeNotifications,
                      onChanged: (val) => ref.read(profileProvider.notifier).updateProfile(user.copyWith(badgeNotifications: val)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  'FiyatRadar, bildirimleri sadece sana özel fırsatlar yakalandığında gönderir. Asla spam yapmaz.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 13, color: Color(0xFF8E8A86), height: 1.45),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _switchTile({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0x148B4D22))),
      ),
      child: Row(
        children: [
          Expanded(
            child: RichText(
              text: TextSpan(
                style: const TextStyle(fontSize: 15, color: Color(0xFF2D241E)),
                children: [
                  TextSpan(text: '$title ', style: const TextStyle(fontWeight: FontWeight.w700)),
                  TextSpan(text: subtitle, style: const TextStyle(color: Color(0xFF8E8A86), fontWeight: FontWeight.w500)),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          CupertinoSwitch(value: value, activeColor: const Color(0xFF8B4D22), onChanged: onChanged),
        ],
      ),
    );
  }
}
