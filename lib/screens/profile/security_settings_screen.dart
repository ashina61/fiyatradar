import 'dart:math' as math;

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/auth_provider.dart';
import '../../providers/profile_provider.dart';
import '../../services/auth_service.dart';
import '../../theme/fr_colors.dart';

enum _SecurityAccordion { email, password }

class SecuritySettingsScreen extends ConsumerStatefulWidget {
  const SecuritySettingsScreen({super.key});

  @override
  ConsumerState<SecuritySettingsScreen> createState() => _SecuritySettingsScreenState();
}

class _SecuritySettingsScreenState extends ConsumerState<SecuritySettingsScreen> {

  final _currentPasswordForEmailController = TextEditingController();
  final _newEmailController = TextEditingController();
  final _currentPasswordForPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();

  _SecurityAccordion? _expanded;
  bool _isUpdatingEmail = false;
  bool _isUpdatingPassword = false;
  int _selectedRenewalPeriod = 3;

  @override
  void dispose() {
    _currentPasswordForEmailController.dispose();
    _newEmailController.dispose();
    _currentPasswordForPasswordController.dispose();
    _newPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentEmail = FirebaseAuth.instance.currentUser?.email?.trim() ?? '';
    final profile = ref.watch(profileProvider).valueOrNull;
    _selectedRenewalPeriod = profile?.passwordRenewalPeriod ?? _selectedRenewalPeriod;

    if (_newEmailController.text.isEmpty && currentEmail.isNotEmpty) {
      _newEmailController.text = currentEmail;
    }

    return Scaffold(
      backgroundColor: FRColors.bgApp,
      appBar: AppBar(
        backgroundColor: FRColors.bgApp,
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
          const _SectionHeader(label: 'Hassas İşlemler'),
          const SizedBox(height: 12),
          _LuxuryCard(
            child: Column(
              children: [
                _AccordionTile(
                  icon: CupertinoIcons.mail,
                  title: 'E-Posta Adresini Değiştir',
                  subtitle: currentEmail.isEmpty ? 'Kayıtlı e-posta bulunamadı' : currentEmail,
                  expanded: _expanded == _SecurityAccordion.email,
                  onTap: () => _toggleSection(_SecurityAccordion.email),
                  child: _EmailAccordionContent(
                    currentPasswordController: _currentPasswordForEmailController,
                    newEmailController: _newEmailController,
                    isBusy: _isUpdatingEmail,
                    onSubmit: _isUpdatingEmail ? null : _handleEmailUpdate,
                  ),
                ),
                const _LuxuryDivider(),
                _AccordionTile(
                  icon: CupertinoIcons.lock_shield,
                  title: 'Şifremi Değiştir',
                  subtitle: 'Mevcut şifreniz ile yeniden doğrulama gerekir',
                  expanded: _expanded == _SecurityAccordion.password,
                  onTap: () => _toggleSection(_SecurityAccordion.password),
                  child: _PasswordAccordionContent(
                    currentPasswordController: _currentPasswordForPasswordController,
                    newPasswordController: _newPasswordController,
                    selectedRenewalPeriod: _selectedRenewalPeriod,
                    onRenewalPeriodChanged: (value) => setState(() => _selectedRenewalPeriod = value),
                    isBusy: _isUpdatingPassword,
                    onSubmit: _isUpdatingPassword ? null : _handlePasswordUpdate,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'E-posta ve şifre değişiklikleri aynı ekranda, akordeon mantığıyla güvenli şekilde ilerler. Her iki işlemde de önce mevcut şifreniz ile yeniden doğrulama yapılır.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: FRColors.textMuted,
              fontSize: 12.5,
              height: 1.55,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  void _toggleSection(_SecurityAccordion section) {
    setState(() {
      _expanded = _expanded == section ? null : section;
    });
  }

  Future<void> _handleEmailUpdate() async {
    final messenger = ScaffoldMessenger.of(context);
    final password = _currentPasswordForEmailController.text.trim();
    final newEmail = _newEmailController.text.trim();

    if (password.isEmpty || newEmail.isEmpty) {
      messenger.showSnackBar(_feedbackBar('Lütfen mevcut şifre ve yeni e-posta alanlarını doldurun.', isError: true));
      return;
    }

    setState(() => _isUpdatingEmail = true);
    try {
      await ref.read(authServiceProvider).updateEmailWithReauth(
            currentPassword: password,
            newEmail: newEmail,
          );
      await ref.read(authNotifierProvider.notifier).refreshCurrentUser();
      await ref.read(profileProvider.notifier).loadProfile();
      ref.invalidate(userModelStreamProvider);
      if (!mounted) return;
      messenger.showSnackBar(_feedbackBar('E-posta adresiniz başarıyla güncellendi.', isError: false));
      setState(() {
        _isUpdatingEmail = false;
        _expanded = null;
        _currentPasswordForEmailController.clear();
      });
    } on FirebaseAuthException catch (error) {
      if (!mounted) return;
      setState(() => _isUpdatingEmail = false);
      messenger.showSnackBar(_feedbackBar(AuthService.mapAuthError(error), isError: true));
    } catch (_) {
      if (!mounted) return;
      setState(() => _isUpdatingEmail = false);
      messenger.showSnackBar(_feedbackBar('E-posta güncellenemedi. Lütfen tekrar deneyin.', isError: true));
    }
  }

  Future<void> _handlePasswordUpdate() async {
    final messenger = ScaffoldMessenger.of(context);
    final currentPassword = _currentPasswordForPasswordController.text.trim();
    final newPassword = _newPasswordController.text.trim();

    if (currentPassword.isEmpty || newPassword.isEmpty) {
      messenger.showSnackBar(_feedbackBar('Lütfen mevcut ve yeni şifre alanlarını doldurun.', isError: true));
      return;
    }

    if (newPassword.length < 6) {
      messenger.showSnackBar(_feedbackBar('Yeni şifre en az 6 karakter olmalıdır.', isError: true));
      return;
    }

    setState(() => _isUpdatingPassword = true);
    try {
      final periodSaved = await ref.read(profileProvider.notifier).updatePasswordRenewalPeriod(_selectedRenewalPeriod);
      if (!periodSaved) {
        throw FirebaseAuthException(
          code: 'password-renewal-period-save-failed',
          message: 'Şifre yenileme periyodu kaydedilemedi.',
        );
      }

      await ref.read(authServiceProvider).updatePasswordWithReauth(
            currentPassword: currentPassword,
            newPassword: newPassword,
          );
      await ref.read(authNotifierProvider.notifier).refreshCurrentUser();
      await ref.read(profileProvider.notifier).loadProfile();
      ref.invalidate(userModelStreamProvider);
      if (!mounted) return;
      messenger.showSnackBar(_feedbackBar('Şifreniz ve yenileme hatırlatıcınız güncellendi.', isError: false));
      setState(() {
        _isUpdatingPassword = false;
        _expanded = null;
        _currentPasswordForPasswordController.clear();
        _newPasswordController.clear();
      });
    } on FirebaseAuthException catch (error) {
      if (!mounted) return;
      setState(() => _isUpdatingPassword = false);
      messenger.showSnackBar(_feedbackBar(AuthService.mapAuthError(error), isError: true));
    } catch (_) {
      if (!mounted) return;
      setState(() => _isUpdatingPassword = false);
      messenger.showSnackBar(_feedbackBar('Şifre güncellenemedi. Lütfen tekrar deneyin.', isError: true));
    }
  }

  SnackBar _feedbackBar(String message, {required bool isError}) {
    return SnackBar(
      content: Text(message),
      backgroundColor: isError ? FRColors.danger : FRColors.espresso,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(
            color: FRColors.shadowSoft,
            blurRadius: 24,
            spreadRadius: 1,
            offset: Offset(0, 12),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _AccordionTile extends StatelessWidget {
  const _AccordionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.expanded,
    required this.onTap,
    required this.child,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool expanded;
  final VoidCallback onTap;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 240),
      curve: Curves.easeOutCubic,
      child: Column(
        children: [
          Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(24),
              onTap: onTap,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: FRColors.backgroundWarm,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: FRColors.borderStrong.withOpacity(0.4)),
                      ),
                      child: Icon(icon, color: FRColors.espresso, size: 20),
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
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    _DiamondArrow(expanded: expanded),
                  ],
                ),
              ),
            ),
          ),
          ClipRect(
            child: AnimatedAlign(
              duration: const Duration(milliseconds: 260),
              curve: Curves.easeOutCubic,
              heightFactor: expanded ? 1 : 0,
              alignment: Alignment.topCenter,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
                child: child,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmailAccordionContent extends StatelessWidget {
  const _EmailAccordionContent({
    required this.currentPasswordController,
    required this.newEmailController,
    required this.isBusy,
    required this.onSubmit,
  });

  final TextEditingController currentPasswordController;
  final TextEditingController newEmailController;
  final bool isBusy;
  final VoidCallback? onSubmit;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 4),
        _LuxuryInputField(
          controller: currentPasswordController,
          label: 'Mevcut Şifre',
          icon: CupertinoIcons.lock,
          obscureText: true,
        ),
        const SizedBox(height: 12),
        _LuxuryInputField(
          controller: newEmailController,
          label: 'Yeni E-Posta',
          icon: CupertinoIcons.mail,
          keyboardType: TextInputType.emailAddress,
        ),
        const SizedBox(height: 16),
        _PrimaryActionButton(
          label: 'E-Postayı Güncelle',
          isBusy: isBusy,
          onTap: onSubmit,
        ),
      ],
    );
  }
}

class _PasswordAccordionContent extends StatelessWidget {
  const _PasswordAccordionContent({
    required this.currentPasswordController,
    required this.newPasswordController,
    required this.selectedRenewalPeriod,
    required this.onRenewalPeriodChanged,
    required this.isBusy,
    required this.onSubmit,
  });

  final TextEditingController currentPasswordController;
  final TextEditingController newPasswordController;
  final int selectedRenewalPeriod;
  final ValueChanged<int> onRenewalPeriodChanged;
  final bool isBusy;
  final VoidCallback? onSubmit;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 4),
        _LuxuryInputField(
          controller: currentPasswordController,
          label: 'Mevcut Şifre',
          icon: CupertinoIcons.lock,
          obscureText: true,
        ),
        const SizedBox(height: 12),
        _LuxuryInputField(
          controller: newPasswordController,
          label: 'Yeni Şifre',
          icon: CupertinoIcons.lock_shield,
          obscureText: true,
        ),
        const SizedBox(height: 16),
        const Text(
          'Şifre Yenileme Hatırlatıcısı',
          style: TextStyle(
            color: FRColors.espresso,
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 10),
        _RenewalSegmentedControl(
          value: selectedRenewalPeriod,
          onChanged: onRenewalPeriodChanged,
        ),
        const SizedBox(height: 16),
        _PrimaryActionButton(
          label: 'Şifreyi Güncelle',
          isBusy: isBusy,
          onTap: onSubmit,
        ),
      ],
    );
  }
}

class _LuxuryInputField extends StatelessWidget {
  const _LuxuryInputField({
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
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: FRColors.bgApp,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: FRColors.borderStrong.withOpacity(0.38)),
      ),
      child: TextField(
        controller: controller,
        obscureText: obscureText,
        keyboardType: keyboardType,
        cursorColor: FRColors.camel,
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
          prefixIcon: Icon(icon, color: FRColors.camelDeep, size: 18),
        ),
      ),
    );
  }
}

class _RenewalSegmentedControl extends StatelessWidget {
  const _RenewalSegmentedControl({
    required this.value,
    required this.onChanged,
  });

  final int value;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: FRColors.background,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: FRColors.borderStrong.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          for (final option in const [1, 3, 6, 12]) ...[
            Expanded(
              child: _RenewalOption(
                label: '$option Ay',
                selected: value == option,
                onTap: () => onChanged(option),
              ),
            ),
            if (option != 12) const SizedBox(width: 6),
          ],
        ],
      ),
    );
  }
}

class _RenewalOption extends StatelessWidget {
  const _RenewalOption({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
      decoration: BoxDecoration(
        color: selected ? FRColors.surface : Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        boxShadow: selected
            ? const [
                BoxShadow(
                  color: FRColors.shadowSoft,
                  blurRadius: 14,
                  offset: Offset(0, 6),
                ),
              ]
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: selected ? FRColors.espresso : FRColors.textMuted,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PrimaryActionButton extends StatelessWidget {
  const _PrimaryActionButton({
    required this.label,
    required this.isBusy,
    required this.onTap,
  });

  final String label;
  final bool isBusy;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 180),
        opacity: onTap == null ? 0.72 : 1,
        child: Container(
          height: 56,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            gradient: const LinearGradient(
              colors: [FRColors.espressoSoft, Color(0xFF090603)],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
            boxShadow: const [
              BoxShadow(
                color: FRColors.shadowMedium,
                blurRadius: 18,
                offset: Offset(0, 10),
              ),
            ],
          ),
          child: Center(
            child: isBusy
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: FRColors.camel,
                    ),
                  )
                : Text(
                    label,
                    style: const TextStyle(
                      color: FRColors.camel,
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}

class _DiamondArrow extends StatelessWidget {
  const _DiamondArrow({required this.expanded});

  final bool expanded;

  @override
  Widget build(BuildContext context) {
    return AnimatedRotation(
      duration: const Duration(milliseconds: 220),
      turns: expanded ? 0.125 : 0,
      child: Transform.rotate(
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
    );
  }
}

class _LuxuryDivider extends StatelessWidget {
  const _LuxuryDivider();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18),
      child: Container(height: 1, color: FRColors.borderStrong.withOpacity(0.4)),
    );
  }
}
