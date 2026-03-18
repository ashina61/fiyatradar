import 'dart:math' as math;

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/auth_provider.dart';
import '../../providers/profile_provider.dart';
import '../../services/auth_service.dart';
import '../../theme/fr_colors.dart';

class SecuritySettingsScreen extends ConsumerWidget {
  const SecuritySettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
                  onTap: () => _showEmailSheet(context, ref, currentEmail ?? ''),
                ),
                const _LuxuryDivider(),
                _SecurityMenuRow(
                  icon: CupertinoIcons.lock_shield,
                  title: 'Şifremi Değiştir',
                  subtitle: 'Hesap güvenliğiniz için yeniden doğrulama gerekir',
                  onTap: () => _showPasswordSheet(context, ref),
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

  Future<void> _showEmailSheet(
    BuildContext context,
    WidgetRef ref,
    String currentEmail,
  ) async {
    final passwordController = TextEditingController();
    final emailController = TextEditingController(text: currentEmail);
    bool isSaving = false;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            Future<void> saveEmail() async {
              final password = passwordController.text.trim();
              final newEmail = emailController.text.trim();
              if (password.isEmpty || newEmail.isEmpty) {
                _showFeedback(
                  sheetContext,
                  message: 'Lütfen tüm alanları doldurun.',
                  isError: true,
                );
                return;
              }

              setModalState(() => isSaving = true);
              try {
                await ref.read(authServiceProvider).updateEmailWithReauth(
                      currentPassword: password,
                      newEmail: newEmail,
                    );
                await ref.read(authNotifierProvider.notifier).refreshCurrentUser();
                await ref.read(profileProvider.notifier).loadProfile();
                ref.invalidate(userModelStreamProvider);
                if (!context.mounted) return;
                Navigator.of(sheetContext).pop();
                _showFeedback(
                  context,
                  message: 'E-posta adresiniz güncellendi.',
                  isError: false,
                );
              } on FirebaseAuthException catch (error) {
                if (!context.mounted) return;
                _showFeedback(
                  context,
                  message: AuthService.mapAuthError(error),
                  isError: true,
                );
              } catch (_) {
                if (!context.mounted) return;
                _showFeedback(
                  context,
                  message: 'E-posta güncellenemedi. Lütfen tekrar deneyin.',
                  isError: true,
                );
              } finally {
                if (context.mounted) {
                  setModalState(() => isSaving = false);
                }
              }
            }

            return _SecuritySheetScaffold(
              title: 'E-Posta Güncelle',
              subtitle: 'Hassas işlemler için mevcut şifrenizle doğrulama yapılır.',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _LuxurySheetField(
                    controller: passwordController,
                    label: 'Mevcut Şifreniz',
                    icon: CupertinoIcons.lock,
                    obscureText: true,
                  ),
                  const SizedBox(height: 14),
                  _LuxurySheetField(
                    controller: emailController,
                    label: 'Yeni E-Posta Adresi',
                    icon: CupertinoIcons.mail,
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: 22),
                  _SheetActionButton(
                    label: 'Kaydet',
                    isBusy: isSaving,
                    onTap: isSaving ? null : saveEmail,
                  ),
                ],
              ),
            );
          },
        );
      },
    );

    passwordController.dispose();
    emailController.dispose();
  }

  Future<void> _showPasswordSheet(BuildContext context, WidgetRef ref) async {
    final currentPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    bool isSaving = false;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            Future<void> savePassword() async {
              final currentPassword = currentPasswordController.text.trim();
              final newPassword = newPasswordController.text.trim();

              if (currentPassword.isEmpty || newPassword.isEmpty) {
                _showFeedback(
                  sheetContext,
                  message: 'Lütfen tüm alanları doldurun.',
                  isError: true,
                );
                return;
              }

              if (newPassword.length < 6) {
                _showFeedback(
                  sheetContext,
                  message: 'Yeni şifre en az 6 karakter olmalıdır.',
                  isError: true,
                );
                return;
              }

              setModalState(() => isSaving = true);
              try {
                await ref.read(authServiceProvider).updatePasswordWithReauth(
                      currentPassword: currentPassword,
                      newPassword: newPassword,
                    );
                if (!context.mounted) return;
                Navigator.of(sheetContext).pop();
                _showFeedback(
                  context,
                  message: 'Şifreniz başarıyla güncellendi.',
                  isError: false,
                );
              } on FirebaseAuthException catch (error) {
                if (!context.mounted) return;
                _showFeedback(
                  context,
                  message: AuthService.mapAuthError(error),
                  isError: true,
                );
              } catch (_) {
                if (!context.mounted) return;
                _showFeedback(
                  context,
                  message: 'Şifre güncellenemedi. Lütfen tekrar deneyin.',
                  isError: true,
                );
              } finally {
                if (context.mounted) {
                  setModalState(() => isSaving = false);
                }
              }
            }

            return _SecuritySheetScaffold(
              title: 'Şifre Güncelle',
              subtitle: 'Mevcut şifreniz doğrulandıktan sonra yeni şifreniz kaydedilir.',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _LuxurySheetField(
                    controller: currentPasswordController,
                    label: 'Mevcut Şifre',
                    icon: CupertinoIcons.lock,
                    obscureText: true,
                  ),
                  const SizedBox(height: 14),
                  _LuxurySheetField(
                    controller: newPasswordController,
                    label: 'Yeni Şifre',
                    icon: CupertinoIcons.lock_shield,
                    obscureText: true,
                  ),
                  const SizedBox(height: 22),
                  _SheetActionButton(
                    label: 'Kaydet',
                    isBusy: isSaving,
                    onTap: isSaving ? null : savePassword,
                  ),
                ],
              ),
            );
          },
        );
      },
    );

    currentPasswordController.dispose();
    newPasswordController.dispose();
  }

  void _showFeedback(
    BuildContext context, {
    required String message,
    required bool isError,
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? FRColors.danger : Colors.green.shade600,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }
}

class _SecuritySheetScaffold extends StatelessWidget {
  const _SecuritySheetScaffold({
    required this.title,
    required this.subtitle,
    required this.child,
  });

  final String title;
  final String subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(16, 24, 16, bottomInset + 16),
      child: Container(
        decoration: BoxDecoration(
          color: FRColors.surface,
          borderRadius: BorderRadius.circular(28),
          boxShadow: const [
            BoxShadow(
              color: FRColors.shadowSoft,
              blurRadius: 28,
              offset: Offset(0, 18),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(22, 18, 22, 22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 56,
                  height: 5,
                  decoration: BoxDecoration(
                    color: FRColors.borderStrong.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Text(
                title,
                style: const TextStyle(
                  color: FRColors.espresso,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
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
              const SizedBox(height: 20),
              child,
            ],
          ),
        ),
      ),
    );
  }
}

class _LuxurySheetField extends StatelessWidget {
  const _LuxurySheetField({
    required this.controller,
    required this.label,
    required this.icon,
    this.obscureText = false,
    this.keyboardType,
  });

  final TextEditingController controller;
  final String label;
  final IconData icon;
  final bool obscureText;
  final TextInputType? keyboardType;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: FRColors.backgroundWarm,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: FRColors.borderStrong.withOpacity(0.45)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: TextField(
        controller: controller,
        obscureText: obscureText,
        keyboardType: keyboardType,
        style: const TextStyle(
          color: FRColors.espresso,
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
        decoration: InputDecoration(
          border: InputBorder.none,
          labelText: label,
          labelStyle: const TextStyle(
            color: FRColors.textMuted,
            fontWeight: FontWeight.w600,
          ),
          prefixIcon: Icon(icon, color: FRColors.textMuted, size: 18),
        ),
      ),
    );
  }
}

class _SheetActionButton extends StatelessWidget {
  const _SheetActionButton({
    required this.label,
    required this.isBusy,
    required this.onTap,
  });

  final String label;
  final bool isBusy;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: Ink(
        height: 56,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          gradient: const LinearGradient(
            colors: [FRColors.espresso, FRColors.camel],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          boxShadow: const [
            BoxShadow(
              color: FRColors.shadowMedium,
              blurRadius: 18,
              offset: Offset(0, 12),
            ),
          ],
        ),
        child: Center(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 220),
            child: isBusy
                ? const SizedBox(
                    key: ValueKey('loading'),
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.4,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : Text(
                    label,
                    key: ValueKey(label),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.2,
                    ),
                  ),
          ),
        ),
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
