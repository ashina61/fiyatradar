import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/user_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/profile_provider.dart';
import '../../theme/fr_colors.dart';

class NotificationSettingsScreen extends ConsumerWidget {
  const NotificationSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileState = ref.watch(userModelStreamProvider);

    return Scaffold(
      backgroundColor: FRColors.background,
      appBar: AppBar(
        backgroundColor: FRColors.background,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: FRColors.espresso),
        title: const Text(
          'Bildirim Tercihleri',
          style: TextStyle(
            color: FRColors.espresso,
            fontSize: 17,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: profileState.when(
        loading: () => const Center(child: CircularProgressIndicator(color: FRColors.espresso)),
        error: (error, _) => Center(child: Text('Bir hata oluştu: $error')),
        data: (user) {
          if (user == null) return const Center(child: Text('Profil bulunamadı.'));

          return ListView(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 40),
            children: [
              const _SectionHeader(label: 'Alışveriş Radarı'),
              const SizedBox(height: 12),
              _SettingsCard(
                child: Column(
                  children: [
                    _NotificationTile(
                      title: 'Fiyat Alarmı Bildirimleri',
                      subtitle: 'Takip ettiğin ürün hedef fiyatı gördüğünde sana anında haber verir.',
                      value: user.alarmNotifications,
                      onChanged: (value) => _updateUser(ref, user.copyWith(alarmNotifications: value)),
                    ),
                    const _LuxuryDivider(),
                    _NotificationTile(
                      title: 'Market Kampanyaları',
                      subtitle: 'Yakınındaki zincir market fırsatlarını ve öne çıkan katalogları özetler.',
                      value: user.campaignNotifications,
                      onChanged: (value) => _updateUser(ref, user.copyWith(campaignNotifications: value)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              const _SectionHeader(label: 'Topluluk ve Kariyer'),
              const SizedBox(height: 12),
              _SettingsCard(
                child: Column(
                  children: [
                    _NotificationTile(
                      title: 'Güven Skoru & Doğrulama',
                      subtitle: 'Doğrulama statün, güven puanın ve kritik hesap hareketlerin için görünür kalır.',
                      value: user.badgeNotifications,
                      onChanged: (value) => _updateUser(ref, user.copyWith(badgeNotifications: value)),
                    ),
                    const _LuxuryDivider(),
                    _NotificationTile(
                      title: 'Rozet ve Lig İlerlemesi',
                      subtitle: 'Yeni rozet, seviye atlama ve kariyer kilometre taşlarında seni sahneye çağırır.',
                      value: user.badgeNotifications,
                      onChanged: (value) => _updateUser(ref, user.copyWith(badgeNotifications: value)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'FiyatRadar, bildirimleri sadece sana özel fırsatlar ve başarılar yakalandığında gönderir. Asla spam yapmaz.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: FRColors.textMuted,
                  fontSize: 12.5,
                  height: 1.55,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _updateUser(WidgetRef ref, UserModel user) {
    return ref.read(profileProvider.notifier).updateProfile(user);
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        label.toUpperCase(),
        style: const TextStyle(
          color: FRColors.espresso,
          fontSize: 11,
          fontWeight: FontWeight.w800,
          letterSpacing: 1.5,
        ),
      ),
    );
  }
}

class _SettingsCard extends StatelessWidget {
  const _SettingsCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: FRColors.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: FRColors.shadowSoft,
            blurRadius: 20,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _NotificationTile extends StatelessWidget {
  const _NotificationTile({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: FRColors.espresso,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: FRColors.textMuted,
                    fontSize: 13,
                    height: 1.45,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          CupertinoSwitch(
            value: value,
            activeColor: FRColors.espresso,
            trackColor: FRColors.borderStrong.withOpacity(0.55),
            thumbColor: FRColors.surface,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}

class _LuxuryDivider extends StatelessWidget {
  const _LuxuryDivider();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18),
      child: Container(height: 1, color: FRColors.borderStrong.withOpacity(0.45)),
    );
  }
}
