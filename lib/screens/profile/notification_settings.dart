import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/profile_provider.dart';

class NotificationSettingsScreen extends ConsumerWidget {
  const NotificationSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Firebase'den veriyi dinliyoruz
    final profileState = ref.watch(profileProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F3F0),
      appBar: AppBar(
        backgroundColor: Colors.white.withOpacity(0.95), elevation: 0, centerTitle: true, iconTheme: const IconThemeData(color: Color(0xFF8B4D22)),
        title: const Text('Bildirimler', style: TextStyle(color: Color(0xFF2D241E), fontSize: 17, fontWeight: FontWeight.w600)),
        bottom: PreferredSize(preferredSize: const Size.fromHeight(1), child: Container(color: const Color(0x148B4D22), height: 1)),
      ),
      body: profileState.when(
        loading: () => const Center(child: CircularProgressIndicator(color: Color(0xFF8B4D22))),
        error: (error, stack) => Center(child: Text('Hata: $error')),
        data: (user) {
          if (user == null) {
            return const Center(child: Text('Profil bulunamadı.'));
          }

          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Container(
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: const Color(0x148B4D22))),
                child: Column(
                  children: [
                    _buildSwitchTile(
                      title: 'Fiyat Alarmı Bildirimleri', 
                      subtitle: 'Takip ettiğin ürün düştüğünde uyar.', 
                      value: user.priceAlarm, 
                      onChanged: (val) {
                        final updatedUser = user.copyWith(priceAlarm: val);
                        ref.read(profileProvider.notifier).updateProfile(updatedUser);
                      }
                    ),
                    const Divider(height: 1, color: Color(0x148B4D22), indent: 20),
                    _buildSwitchTile(
                      title: 'Kampanya Bildirimleri', 
                      subtitle: 'Haftalık indirimleri bildirir.', 
                      value: user.campaignNotification, 
                      onChanged: (val) {
                        final updatedUser = user.copyWith(campaignNotification: val);
                        ref.read(profileProvider.notifier).updateProfile(updatedUser);
                      }
                    ),
                    const Divider(height: 1, color: Color(0x148B4D22), indent: 20),
                    _buildSwitchTile(
                      title: 'Rozet ve Puan Bildirimleri', 
                      subtitle: 'Liderlik tablosu değişimleri.', 
                      value: user.badgeNotification, 
                      onChanged: (val) {
                        final updatedUser = user.copyWith(badgeNotification: val);
                        ref.read(profileProvider.notifier).updateProfile(updatedUser);
                      }
                    ),
                  ],
                ),
              ),
              const Padding(
                padding: EdgeInsets.only(top: 16, left: 20, right: 20),
                child: Text('FiyatRadar spam yapmaz, sadece sana özel fırsatlar yakalandığında bildirim gönderir.', textAlign: TextAlign.center, style: TextStyle(color: Color(0xFF8E8A86), fontSize: 12)),
              )
            ],
          );
        },
      ),
    );
  }

  Widget _buildSwitchTile({required String title, required String subtitle, required bool value, required ValueChanged<bool> onChanged}) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      title: Text(title, style: const TextStyle(color: Color(0xFF2D241E), fontSize: 15, fontWeight: FontWeight.w600)),
      subtitle: Text(subtitle, style: const TextStyle(color: Color(0xFF8E8A86), fontSize: 13)),
      trailing: CupertinoSwitch(value: value, activeColor: const Color(0xFF8B4D22), onChanged: onChanged),
    );
  }
}
