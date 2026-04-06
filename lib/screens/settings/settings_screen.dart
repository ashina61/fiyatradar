import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/design_system/tokens/colors.dart';
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
    return Scaffold(
      backgroundColor: FRDsColors.frBackground,
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 10, 18, 150),
          children: [
            _TopArea(onBack: () => Navigator.of(context).maybePop()),
            const SizedBox(height: 22),
            if (isAdmin)
              _PremiumActionTile(
                title: 'Admin Konsolu',
                icon: CupertinoIcons.lock_shield,
                trailingLabel: null,
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const AdminPanelScreen()),
                ),
              ),
            if (isAdmin) const SizedBox(height: 24),
            const _SectionTitle('HESAP & TERCİHLER'),
            const SizedBox(height: 10),
            _GroupedTiles(
              children: [
                _UtilityTile(
                  title: 'Kişisel Bilgiler',
                  icon: CupertinoIcons.person,
                  onTap: () => Navigator.of(context).push(
                    CupertinoPageRoute(builder: (_) => const PersonalInfoScreen()),
                  ),
                ),
                _UtilityTile(
                  title: 'Güvenlik ve Giriş',
                  icon: CupertinoIcons.lock_shield,
                  onTap: () => Navigator.of(context).push(
                    CupertinoPageRoute(builder: (_) => const SecuritySettingsScreen()),
                  ),
                ),
                _UtilityTile(
                  title: 'Bildirim Tercihleri',
                  icon: CupertinoIcons.bell,
                  onTap: () => Navigator.of(context).push(
                    CupertinoPageRoute(builder: (_) => const NotificationSettingsScreen()),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            const _SectionTitle('SİSTEM & GÜNCELLEMELER'),
            const SizedBox(height: 10),
            _GroupedTiles(
              children: [
                _UtilityTile(
                  title: 'Sıkça Sorulan Sorular (SSS)',
                  icon: CupertinoIcons.question_circle,
                  onTap: () => Navigator.of(context).push(
                    CupertinoPageRoute(builder: (_) => const HelpAndFaqScreen()),
                  ),
                ),
                _UtilityTile(
                  title: 'Bize Ulaşın',
                  icon: CupertinoIcons.mail,
                  onTap: () => _openUrl(context, 'mailto:fiyatradar.app@gmail.com'),
                ),
                _UtilityTile(
                  title: 'Uygulamayı Puanla',
                  icon: CupertinoIcons.star,
                  onTap: () => _openUrl(context, 'https://fiyatradar.com'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _PremiumActionTile(
              title: 'Güncelleme Geçmişi',
              icon: CupertinoIcons.sparkles,
              trailingLabel: 'FR 3.1',
              onTap: () => Navigator.of(context).push(
                CupertinoPageRoute(builder: (_) => const ChangelogScreen()),
              ),
            ),
            const SizedBox(height: 24),
            const _SectionTitle('YASAL'),
            const SizedBox(height: 10),
            _GroupedTiles(
              children: [
                _UtilityTile(
                  title: 'Kullanım Koşulları',
                  icon: CupertinoIcons.doc_text,
                  onTap: () => _openUrl(context, 'https://fiyatradar.netlify.app/sozlesme.html'),
                ),
                _UtilityTile(
                  title: 'Gizlilik Politikası',
                  icon: CupertinoIcons.lock,
                  onTap: () => _openUrl(context, 'https://fiyatradar.netlify.app/gizlilik.html'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _WideButton(
              label: 'Güvenli Çıkış Yap',
              onTap: () => _confirmAction(
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
            const SizedBox(height: 12),
            _WideButton(
              label: 'Hesabı Kalıcı Olarak Sil',
              danger: true,
              onTap: () => _confirmAction(
                context,
                title: 'Silme talebi gönderilsin mi?',
                message: 'İşlem geri alınamaz, destek e-postası açılacak.',
                onConfirm: () => _openUrl(context, 'mailto:fiyatradar.app@gmail.com'),
              ),
            ),
          ],
        ),
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

class _TopArea extends StatelessWidget {
  const _TopArea({required this.onBack});
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: onBack,
          child: Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: FRDsColors.frSurface,
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Icon(CupertinoIcons.back, size: 24),
          ),
        ),
        const SizedBox(height: 24),
        const Text(
          'Ayarlar',
          style: TextStyle(
            fontSize: 56,
            fontWeight: FontWeight.w800,
            color: Color(0xFF1A100C),
            height: 1.0,
          ),
        ),
        const SizedBox(height: 10),
        const Text(
          'EXECUTIVE DASHBOARD',
          style: TextStyle(
            fontSize: 15,
            letterSpacing: 2.4,
            fontWeight: FontWeight.w700,
            color: FRDsColors.frTextMuted,
          ),
        ),
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.value);
  final String value;

  @override
  Widget build(BuildContext context) {
    return Text(
      value,
      style: const TextStyle(
        fontSize: 13,
        letterSpacing: 2.4,
        fontWeight: FontWeight.w700,
        color: FRDsColors.frTextMuted,
      ),
    );
  }
}

class _GroupedTiles extends StatelessWidget {
  const _GroupedTiles({required this.children});
  final List<_UtilityTile> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: FRDsColors.frSurface,
        borderRadius: BorderRadius.circular(30),
      ),
      child: Column(
        children: [
          for (var i = 0; i < children.length; i++) ...[
            children[i],
            if (i != children.length - 1)
              const Divider(height: 1, indent: 22, endIndent: 22, color: Color(0x0F2A1D16)),
          ],
        ],
      ),
    );
  }
}

class _UtilityTile extends StatelessWidget {
  const _UtilityTile({required this.title, required this.icon, required this.onTap});

  final String title;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(30),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
        child: Row(
          children: [
            Icon(icon, color: const Color(0xFF1A100C), size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF1A100C),
                ),
              ),
            ),
            const Icon(CupertinoIcons.smallcircle_fill_circle, color: Color(0x1E1A100C), size: 16),
          ],
        ),
      ),
    );
  }
}

class _PremiumActionTile extends StatelessWidget {
  const _PremiumActionTile({
    required this.title,
    required this.icon,
    required this.onTap,
    required this.trailingLabel,
  });

  final String title;
  final IconData icon;
  final VoidCallback onTap;
  final String? trailingLabel;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(26),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        decoration: BoxDecoration(
          color: const Color(0xFF1E120D),
          borderRadius: BorderRadius.circular(26),
          boxShadow: const [
            BoxShadow(
              color: Color(0x26120A06),
              blurRadius: 16,
              offset: Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(icon, color: const Color(0xFFE0B67D)),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  color: Color(0xFFE4BF8E),
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            if (trailingLabel != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFFE6C08F),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  trailingLabel!,
                  style: const TextStyle(
                    color: Color(0xFF2A1A14),
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                  ),
                ),
              ),
            const SizedBox(width: 8),
            const Icon(CupertinoIcons.smallcircle_fill_circle_fill, color: Color(0xFFE0B67D), size: 20),
          ],
        ),
      ),
    );
  }
}

class _WideButton extends StatelessWidget {
  const _WideButton({required this.label, required this.onTap, this.danger = false});

  final String label;
  final VoidCallback onTap;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(24),
      onTap: onTap,
      child: Container(
        height: 66,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: danger ? const Color(0xFFFFF1F0) : FRDsColors.frSurface,
          borderRadius: BorderRadius.circular(24),
          border: danger ? Border.all(color: const Color(0xFFF4D5D2)) : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            color: danger ? FRDsColors.frDanger : const Color(0xFF1A100C),
            fontWeight: FontWeight.w800,
            fontSize: 22,
          ),
        ),
      ),
    );
  }
}
