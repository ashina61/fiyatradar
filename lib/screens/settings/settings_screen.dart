import 'dart:math' as math;

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../theme/fr_colors.dart';
import '../admin/admin_panel_screen.dart';
import '../auth/login_screen.dart';
import '../profile/notification_settings.dart';
import '../profile/personal_info_screen.dart';
import '../profile/security_screen.dart';
import 'changelog_screen.dart';
import 'help_and_faq_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key, required this.isAdmin});

  final bool isAdmin;

  Future<void> _openUrl(BuildContext context, String rawUrl) async {
    final uri = Uri.parse(rawUrl);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication) && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bağlantı açılamadı.')),
      );
    }
  }

  Future<void> _launchEmail(BuildContext context) async {
    await _openUrl(context, 'mailto:destek@fiyatradar.com');
  }

  Future<void> _confirmAction({
    required BuildContext context,
    required String title,
    required String message,
    required String actionLabel,
    required Color actionColor,
    required Future<void> Function() onConfirm,
  }) async {
    final approved = await showCupertinoDialog<bool>(
      context: context,
      builder: (dialogContext) => CupertinoAlertDialog(
        title: Text(title),
        content: Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Text(message),
        ),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Vazgeç'),
          ),
          CupertinoDialogAction(
            isDestructiveAction: actionColor == Colors.red,
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(actionLabel),
          ),
        ],
      ),
    );

    if (approved == true) {
      await onConfirm();
    }
  }

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.paddingOf(context).top;
    return Scaffold(
      backgroundColor: FRColors.background,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(24, topPadding + 18, 24, 10),
              child: Row(
                children: [
                  _HeaderButton(
                    icon: CupertinoIcons.back,
                    onTap: () => Navigator.of(context).maybePop(),
                  ),
                  const Spacer(),
                ],
              ),
            ),
          ),
          const SliverToBoxAdapter(child: _SettingsHeader()),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 40),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _VipMenuCard(
                  icon: CupertinoIcons.person_2_square_stack,
                  title: 'Admin Konsolu',
                  visible: isAdmin,
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const AdminPanelScreen()),
                  ),
                ),
                const SizedBox(height: 24),
                _MenuSection(
                  title: 'HESAP & TERCİHLER',
                  items: [
                    _SettingsMenuItem(
                      icon: CupertinoIcons.person,
                      title: 'Kişisel Bilgiler & Konum',
                      onTap: () => Navigator.of(context).push(
                        CupertinoPageRoute(builder: (_) => const PersonalInfoScreen()),
                      ),
                    ),
                    _SettingsMenuItem(
                      icon: CupertinoIcons.lock_shield,
                      title: 'Güvenlik ve Giriş',
                      onTap: () => Navigator.of(context).push(
                        CupertinoPageRoute(builder: (_) => const SecurityScreen()),
                      ),
                    ),
                    _SettingsMenuItem(
                      icon: CupertinoIcons.bell,
                      title: 'Bildirim Tercihleri',
                      onTap: () => Navigator.of(context).push(
                        CupertinoPageRoute(builder: (_) => const NotificationSettingsScreen()),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                _MenuSection(
                  title: 'SİSTEM & GÜNCELLEMELER',
                  items: [
                    _SettingsMenuItem(
                      icon: CupertinoIcons.question_circle,
                      title: 'Sıkça Sorulan Sorular (SSS)',
                      onTap: () => Navigator.of(context).push(
                        CupertinoPageRoute(builder: (_) => const HelpAndFaqScreen()),
                      ),
                    ),
                    _SettingsMenuItem(
                      icon: CupertinoIcons.mail,
                      title: 'Bize Ulaşın',
                      onTap: () => _launchEmail(context),
                    ),
                    _SettingsMenuItem(
                      icon: CupertinoIcons.star,
                      title: 'Uygulamayı Puanla',
                      onTap: () => _openUrl(context, 'https://fiyatradar.com'),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _VipMenuCard(
                  icon: CupertinoIcons.sparkles,
                  title: 'Güncelleme Geçmişi',
                  tag: 'FR 3.1',
                  onTap: () => Navigator.of(context).push(
                    CupertinoPageRoute(builder: (_) => const ChangelogScreen()),
                  ),
                ),
                const SizedBox(height: 24),
                _MenuSection(
                  title: 'YASAL',
                  items: [
                    _SettingsMenuItem(
                      icon: CupertinoIcons.doc_text,
                      title: 'Kullanım Koşulları',
                      onTap: () => _openUrl(context, 'https://fiyatradar.com/kullanim-kosullari'),
                    ),
                    _SettingsMenuItem(
                      icon: CupertinoIcons.lock_doc,
                      title: 'Gizlilik Politikası',
                      onTap: () => _openUrl(context, 'https://fiyatradar.com/gizlilik'),
                    ),
                  ],
                ),
                const SizedBox(height: 32),
                _ActionCard(
                  label: 'Güvenli Çıkış Yap',
                  foregroundColor: FRColors.espresso,
                  backgroundColor: FRColors.surface,
                  borderColor: FRColors.border,
                  onTap: () => _confirmAction(
                    context: context,
                    title: 'Güvenli çıkış yapılsın mı?',
                    message: 'Aktif oturum kapatılacak ve giriş ekranına dönülecek.',
                    actionLabel: 'Çıkış Yap',
                    actionColor: FRColors.espresso,
                    onConfirm: () async {
                      await FirebaseAuth.instance.signOut();
                      if (!context.mounted) return;
                      Navigator.of(context).pushAndRemoveUntil(
                        MaterialPageRoute(builder: (_) => const LoginScreen()),
                        (route) => false,
                      );
                    },
                  ),
                ),
                const SizedBox(height: 16),
                _ActionCard(
                  label: 'Hesabı Kalıcı Olarak Sil',
                  foregroundColor: Colors.red,
                  backgroundColor: const Color(0xFFFFF5F5),
                  borderColor: Colors.red.withOpacity(0.15),
                  onTap: () => _confirmAction(
                    context: context,
                    title: 'Kalıcı silme talebi',
                    message: 'Bu işlem geri alınamaz. Şimdilik destek ekibine e-posta ile yönlendirileceksiniz.',
                    actionLabel: 'Silme Talebi Gönder',
                    actionColor: Colors.red,
                    onConfirm: () => _launchEmail(context),
                  ),
                ),
                const SizedBox(height: 40),
                const _FooterNote(),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

class _SettingsHeader extends StatelessWidget {
  const _SettingsHeader();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.fromLTRB(24, 10, 24, 30),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Ayarlar',
            style: TextStyle(
              fontSize: 34,
              fontWeight: FontWeight.w900,
              letterSpacing: -1,
              color: FRColors.espresso,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'EXECUTIVE DASHBOARD',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: FRColors.textMutedSoft,
              letterSpacing: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

class _HeaderButton extends StatelessWidget {
  const _HeaderButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: FRColors.surface,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: FRColors.espresso.withOpacity(0.03),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Icon(icon, size: 18, color: FRColors.espresso),
        ),
      ),
    );
  }
}

class _MenuSection extends StatelessWidget {
  const _MenuSection({required this.title, required this.items});

  final String title;
  final List<_SettingsMenuItem> items;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 8, bottom: 12),
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: FRColors.textMutedSoft,
              letterSpacing: 1.2,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: FRColors.surface,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: FRColors.border),
            boxShadow: [
              BoxShadow(
                color: FRColors.espresso.withOpacity(0.02),
                blurRadius: 32,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: Column(
            children: [
              for (int index = 0; index < items.length; index++) ...[
                items[index],
                if (index != items.length - 1)
                  Divider(height: 1, color: FRColors.espresso.withOpacity(0.04)),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _SettingsMenuItem extends StatelessWidget {
  const _SettingsMenuItem({
    required this.icon,
    required this.title,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
          child: Row(
            children: [
              Icon(icon, size: 20, color: FRColors.espresso),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: FRColors.espresso,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              const _DiamondSpark(),
            ],
          ),
        ),
      ),
    );
  }
}

class _VipMenuCard extends StatelessWidget {
  const _VipMenuCard({
    required this.icon,
    required this.title,
    required this.onTap,
    this.tag,
    this.visible = true,
  });

  final IconData icon;
  final String title;
  final VoidCallback onTap;
  final String? tag;
  final bool visible;

  @override
  Widget build(BuildContext context) {
    if (!visible) return const SizedBox.shrink();

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            FRColors.espresso.withOpacity(0.95),
            const Color(0xFF0A0604),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: FRColors.camel.withOpacity(0.4)),
        boxShadow: [
          BoxShadow(
            color: FRColors.espresso.withOpacity(0.2),
            blurRadius: 50,
            offset: const Offset(0, 20),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          children: [
            Positioned(
              top: -50,
              right: -50,
              child: IgnorePointer(
                child: Container(
                  width: 150,
                  height: 150,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        FRColors.camel.withOpacity(0.25),
                        Colors.transparent,
                      ],
                      stops: const [0, 0.7],
                    ),
                  ),
                ),
              ),
            ),
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: onTap,
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      Icon(icon, size: 20, color: FRColors.camel),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Text(
                          title,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: FRColors.camel,
                          ),
                        ),
                      ),
                      if (tag != null) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: FRColors.camel,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            tag!,
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.5,
                              color: FRColors.espresso,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                      ],
                      const _DiamondSpark(isVip: true),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DiamondSpark extends StatelessWidget {
  const _DiamondSpark({this.isVip = false});

  final bool isVip;

  @override
  Widget build(BuildContext context) {
    final outerColor = isVip ? FRColors.camel : FRColors.espresso.withOpacity(0.06);
    final innerColor = isVip ? FRColors.espresso : FRColors.surface;

    return Transform.rotate(
      angle: math.pi / 4,
      child: Container(
        width: 16,
        height: 16,
        decoration: BoxDecoration(
          color: outerColor,
          borderRadius: BorderRadius.circular(3),
          boxShadow: isVip
              ? [
                  BoxShadow(
                    color: FRColors.camel.withOpacity(0.5),
                    blurRadius: 10,
                  ),
                ]
              : null,
        ),
        alignment: Alignment.center,
        child: Container(
          width: 6,
          height: 6,
          decoration: BoxDecoration(
            color: innerColor,
            borderRadius: BorderRadius.circular(1.5),
          ),
        ),
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  const _ActionCard({
    required this.label,
    required this.foregroundColor,
    required this.backgroundColor,
    required this.borderColor,
    required this.onTap,
  });

  final String label;
  final Color foregroundColor;
  final Color backgroundColor;
  final Color borderColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 18),
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: borderColor),
            boxShadow: [
              BoxShadow(
                color: FRColors.espresso.withOpacity(0.02),
                blurRadius: 24,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: foregroundColor,
            ),
          ),
        ),
      ),
    );
  }
}

class _FooterNote extends StatelessWidget {
  const _FooterNote();

  @override
  Widget build(BuildContext context) {
    return const Text(
      'FiyatRadar Sürüm 3.1.0\n© 2026 FiyatRadar A.Ş.',
      textAlign: TextAlign.center,
      style: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: Color(0xFFBDB5AD),
        height: 1.5,
      ),
    );
  }
}
