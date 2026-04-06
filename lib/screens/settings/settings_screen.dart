import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/design_system/design_system.dart';
import '../../providers/auth_provider.dart';
import '../admin/admin_panel_screen.dart';
import '../auth/login_screen.dart';
import '../profile/notification_settings.dart';
import '../profile/personal_info_screen.dart';
import '../profile/security_screen.dart';
import 'changelog_screen.dart';
import 'help_and_faq_screen.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key, required this.isAdmin});

  final bool isAdmin;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return FRAppScaffold(
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: FRDarkHero(
              title: 'Ayarlar',
              subtitle: 'Hesap, sistem ve yasal yönetim merkezi',
              kicker: const FRKickerPill('System Confidence'),
              leading: FRHeroActionButton(
                icon: CupertinoIcons.back,
                onPressed: () => Navigator.of(context).maybePop(),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: FRPageContainer(
              child: Padding(
                padding: const EdgeInsets.only(top: FRDsSpacing.space20),
                child: FRAccountShortcutsSection(
                  eyebrow: 'HESAP & TERCİHLER',
                  title: 'Hızlı erişim',
                  children: [
                    if (isAdmin)
                      Padding(
                        padding: const EdgeInsets.only(bottom: FRDsSpacing.space8),
                        child: FRInfoRowCard(
                          title: 'Admin Konsolu',
                          subtitle: 'Yönetim modülleri',
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => const AdminPanelScreen()),
                          ),
                        ),
                      ),
                    _item(
                      title: 'Kişisel Bilgiler',
                      subtitle: 'Kimlik ve profil alanı',
                      onTap: () => Navigator.of(context).push(
                        CupertinoPageRoute(builder: (_) => const PersonalInfoScreen()),
                      ),
                    ),
                    _item(
                      title: 'Güvenlik ve Giriş',
                      subtitle: 'Parola ve oturum',
                      onTap: () => Navigator.of(context).push(
                        CupertinoPageRoute(builder: (_) => const SecuritySettingsScreen()),
                      ),
                    ),
                    _item(
                      title: 'Bildirim Tercihleri',
                      subtitle: 'Alarm ve kampanya ayarları',
                      onTap: () => Navigator.of(context).push(
                        CupertinoPageRoute(builder: (_) => const NotificationSettingsScreen()),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: FRPageContainer(
              child: Padding(
                padding: const EdgeInsets.only(top: FRDsSpacing.space20),
                child: FRAccountShortcutsSection(
                  eyebrow: 'SİSTEM & DESTEK',
                  title: 'Yardım ve güncellemeler',
                  children: [
                    _item(
                      title: 'Yardım ve SSS',
                      subtitle: 'Sık sorulan sorular',
                      onTap: () => Navigator.of(context).push(
                        CupertinoPageRoute(builder: (_) => const HelpAndFaqScreen()),
                      ),
                    ),
                    _item(
                      title: 'Güncelleme Geçmişi',
                      subtitle: 'Sürüm notları',
                      onTap: () => Navigator.of(context).push(
                        CupertinoPageRoute(builder: (_) => const ChangelogScreen()),
                      ),
                    ),
                    _item(
                      title: 'Bize Ulaşın',
                      subtitle: 'fiyatradar.app@gmail.com',
                      onTap: () => _openUrl(context, 'mailto:fiyatradar.app@gmail.com'),
                    ),
                    _item(
                      title: 'Uygulamayı Puanla',
                      subtitle: 'Web sayfasını aç',
                      onTap: () => _openUrl(context, 'https://fiyatradar.com'),
                    ),
                    _item(
                      title: 'Kullanım Koşulları',
                      subtitle: 'Yasal metin',
                      onTap: () => _openUrl(context, 'https://fiyatradar.netlify.app/sozlesme.html'),
                    ),
                    _item(
                      title: 'Gizlilik Politikası',
                      subtitle: 'KVKK ve gizlilik',
                      onTap: () => _openUrl(context, 'https://fiyatradar.netlify.app/gizlilik.html'),
                    ),
                  ],
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: FRPageContainer(
              child: Padding(
                padding: const EdgeInsets.only(top: FRDsSpacing.space20, bottom: FRDsSpacing.space32),
                child: FRSurfaceCard(
                  child: Column(
                    children: [
                      FRSecondaryButton(
                        label: 'Güvenli Çıkış Yap',
                        onPressed: () => _confirmAction(
                          context,
                          title: 'Çıkış yapılsın mı?',
                          message: 'Aktif oturum kapanacak ve giriş ekranına dönülecek.',
                          onConfirm: () async {
                            await ref.read(authNotifierProvider.notifier).signOut();
                            if (!context.mounted) return;
                            Navigator.of(context).pushAndRemoveUntil(
                              MaterialPageRoute(builder: (_) => const LoginScreen()),
                              (route) => false,
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: FRDsSpacing.space8),
                      FRGhostButton(
                        label: 'Hesabı Kalıcı Olarak Sil',
                        onPressed: () => _confirmAction(
                          context,
                          title: 'Silme talebi gönderilsin mi?',
                          message: 'İşlem geri alınamaz, destek e-postası açılacak.',
                          onConfirm: () => _openUrl(context, 'mailto:fiyatradar.app@gmail.com'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _item({
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: FRDsSpacing.space8),
      child: FRInfoRowCard(
        title: title,
        subtitle: subtitle,
        onTap: onTap,
      ),
    );
  }

  Future<void> _openUrl(BuildContext context, String rawUrl) async {
    final uri = Uri.parse(rawUrl);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication) && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Bağlantı açılamadı.')));
    }
  }

  Future<void> _confirmAction(
    BuildContext context, {
    required String title,
    required String message,
    required Future<void> Function() onConfirm,
  }) async {
    final approved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: [
            TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('Vazgeç')),
            FilledButton(onPressed: () => Navigator.pop(dialogContext, true), child: const Text('Onayla')),
          ],
        );
      },
    );

    if (approved == true) {
      await onConfirm();
    }
  }
}
