import 'dart:math' as math;

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../theme/fr_colors.dart';

class SecuritySettingsScreen extends StatelessWidget {
  const SecuritySettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final currentEmail = FirebaseAuth.instance.currentUser?.email?.trim();

    return Scaffold(
      backgroundColor: FRColors.background,
      appBar: AppBar(
        backgroundColor: FRColors.background,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: FRColors.espresso),
        title: const Text(
          'Güvenlik ve Giriş',
          style: TextStyle(
            color: FRColors.espresso,
            fontSize: 17,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 40),
        children: [
          const _SectionHeader(label: 'Giriş Güvenliği'),
          const SizedBox(height: 12),
          _LuxuryCard(
            child: Column(
              children: [
                _SecurityMenuRow(
                  icon: CupertinoIcons.mail,
                  title: 'E-Posta Adresini Değiştir',
                  subtitle: (currentEmail == null || currentEmail.isEmpty) ? 'test@test.com' : currentEmail,
                  onTap: () {
                    // TODO: E-posta güncelleme bottom sheet'i burada açılacak.
                  },
                ),
                const _LuxuryDivider(),
                _SecurityMenuRow(
                  icon: CupertinoIcons.lock_shield,
                  title: 'Şifremi Değiştir',
                  subtitle: 'Son değişim: 2 ay önce',
                  onTap: () {
                    // TODO: Şifre güncelleme bottom sheet'i burada açılacak.
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Şifre ve E-Posta değişikliklerinde güvenliğiniz için onay kodu istenecektir.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: FRColors.textMuted,
              fontSize: 12.5,
              height: 1.5,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
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

class _LuxuryCard extends StatelessWidget {
  const _LuxuryCard({required this.child});

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

class _SecurityMenuRow extends StatelessWidget {
  const _SecurityMenuRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: FRColors.backgroundWarm,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: FRColors.borderStrong.withOpacity(0.5)),
                ),
                child: Icon(icon, color: FRColors.espresso, size: 21),
              ),
              const SizedBox(width: 14),
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
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: FRColors.textMuted,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Transform.rotate(
                angle: math.pi / 4,
                child: Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: FRColors.camel,
                    borderRadius: BorderRadius.circular(3),
                    boxShadow: const [
                      BoxShadow(
                        color: FRColors.shadowMedium,
                        blurRadius: 8,
                        offset: Offset(0, 3),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
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
