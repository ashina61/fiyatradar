import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../providers/auth_provider.dart';
import '../../providers/firebase_init_provider.dart';
import '../main_screen.dart';
import 'widgets/auth_portal_widgets.dart';


class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _inviteController = TextEditingController();
  final _emailController = TextEditingController();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();


  static const _legalConsentVersion = 'v1.0';
  static const _hostingBase = 'https://fiyatradar-611967.web.app';
  static final _termsUri = Uri.parse('$_hostingBase/sozlesme.html');
  static final _privacyUri = Uri.parse('$_hostingBase/gizlilik.html');

  bool _isLoading = false;
  bool _isGoogleLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _legalConsentAccepted = false;

  static final RegExp _usernamePattern = RegExp(r'^[a-z0-9_]{3,20}$');
  static final RegExp _emailPattern = RegExp(r'^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$');
  static final RegExp _strongPasswordPattern = RegExp(r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d).{8,}$');

  @override
  void dispose() {
    _nameController.dispose();
    _inviteController.dispose();
    _emailController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;
    if (!ref.read(firebaseInitializedProvider)) {
      _showError('Firebase bağlantısı kurulamadı. Lütfen internet bağlantınızı kontrol edin.');
      return;
    }
    if (!_legalConsentAccepted) {
      _showError('Lütfen devam etmek için koşulları onaylayın.');
      return;
    }

    setState(() => _isLoading = true);
    try {
      final user = await ref.read(authNotifierProvider.notifier).register(
            email: _emailController.text.trim(),
            password: _passwordController.text,
            name: _nameController.text.trim(),
            inviteCode: _inviteController.text.trim(),
            username: _usernameController.text.trim(),
            legalConsentVersion: _legalConsentVersion,
          );
      if (user == null) {
        _showError('Kullanıcı profili yüklenemedi.');
        return;
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Kayıt başarılı! Lütfen gelen kutunuzu kontrol edin ve içeri girmeden önce e-postanızı onaylayın.',
            style: authText(size: 12, weight: FontWeight.w700, color: Colors.white),
          ),
          behavior: SnackBarBehavior.floating,
          backgroundColor: authEspresso,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          duration: const Duration(seconds: 6),
        ),
      );
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const MainScreen()),
        (route) => false,
      );
    } on FirebaseAuthException catch (e) {
      _showError(ref.read(authServiceProvider).getErrorMessage(e));
    } catch (e) {
      _showError('Kayıt oluşturulamadı: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _googleRegister() async {
    if (!ref.read(firebaseInitializedProvider)) {
      _showError('Firebase bağlantısı kurulamadı. Lütfen internet bağlantınızı kontrol edin.');
      return;
    }

    if (!_legalConsentAccepted) {
      _showError('Lütfen devam etmek için koşulları onaylayın.');
      return;
    }

    setState(() => _isGoogleLoading = true);
    try {
      final user = await ref.read(authNotifierProvider.notifier).signInWithGoogle(
            recordLegalConsent: true,
            legalConsentVersion: _legalConsentVersion,
          );
      if (user != null && mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const MainScreen()),
          (route) => false,
        );
      }
    } on FirebaseAuthException catch (e) {
      _showError(ref.read(authServiceProvider).getErrorMessage(e));
    } catch (_) {
      _showError('Google ile kayıt oluşturulamadı.');
    } finally {
      if (mounted) setState(() => _isGoogleLoading = false);
    }
  }

  void _showError(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: authText(size: 12, weight: FontWeight.w700, color: Colors.white)),
        behavior: SnackBarBehavior.floating,
        backgroundColor: authEspresso,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }

  Future<void> _openTerms() async {
    await launchUrl(_termsUri, mode: LaunchMode.externalApplication);
  }

  Future<void> _openPrivacy() async {
    await launchUrl(_privacyUri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    return AuthSurface(
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AuthTopBackButton(onTap: () => context.go('/login')),
              const SizedBox(height: 20),
              const AuthHeaderTexts(
                title: 'Aramıza Katıl.',
                subtitle: 'Piyasayı değiştirecek avcı profilini oluştur.',
              ),
              const SizedBox(height: 24),
              AuthInputField(
                label: 'Ad Soyad',
                hint: 'Ad Soyad',
                icon: Icons.person_outline_rounded,
                controller: _nameController,
                textInputAction: TextInputAction.next,
                validator: (v) => (v == null || v.trim().length < 2) ? 'Ad soyad gerekli' : null,
              ),
              const SizedBox(height: 14),
              AuthInputField(
                label: 'Davet Kodu (Opsiyonel)',
                hint: 'Davet Kodu',
                icon: Icons.person_add_alt_rounded,
                controller: _inviteController,
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 14),
              AuthInputField(
                label: 'Kullanıcı Adı',
                hint: 'Sistemde görünecek anonim adınız',
                icon: Icons.alternate_email_rounded,
                controller: _usernameController,
                textInputAction: TextInputAction.next,
                textCapitalization: TextCapitalization.none,
                prefixText: '@',
                helperText: '3-20 karakter, sadece küçük harf, rakam ve alt çizgi kullanın.',
                validator: (v) {
                  final username = (v ?? '').trim();
                  if (username.isEmpty) return 'Kullanıcı adı gerekli';
                  if (username.contains(' ')) return 'Kullanıcı adında boşluk olamaz';
                  if (username != username.toLowerCase()) return 'Kullanıcı adı küçük harf olmalı';
                  if (!_usernamePattern.hasMatch(username)) {
                    return 'Geçerli bir kullanıcı adı girin';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 14),
              AuthInputField(
                label: 'E-Posta Adresi',
                hint: 'E-posta adresin',
                icon: Icons.mail_outline_rounded,
                keyboardType: TextInputType.emailAddress,
                controller: _emailController,
                textInputAction: TextInputAction.next,
                validator: (v) {
                  final email = (v ?? '').trim();
                  if (email.isEmpty) return 'E-posta gerekli';
                  if (!_emailPattern.hasMatch(email)) {
                    return 'Lütfen geçerli bir e-posta adresi girin.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 14),
              AuthInputField(
                label: 'Şifre',
                hint: 'Şifre',
                icon: Icons.lock_outline_rounded,
                controller: _passwordController,
                obscureText: _obscurePassword,
                textInputAction: TextInputAction.next,
                suffix: IconButton(
                  onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                  icon: Icon(_obscurePassword ? Icons.visibility_off_rounded : Icons.visibility_rounded, color: authMuted),
                ),
                validator: (v) {
                  final password = v ?? '';
                  if (!_strongPasswordPattern.hasMatch(password)) {
                    return 'Şifre en az 8 karakter, 1 büyük harf ve 1 rakam içermelidir.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 14),
              AuthInputField(
                label: 'Şifre Tekrar',
                hint: 'Şifre Tekrar',
                icon: Icons.lock_reset_rounded,
                controller: _confirmPasswordController,
                obscureText: _obscureConfirmPassword,
                textInputAction: TextInputAction.done,
                suffix: IconButton(
                  onPressed: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
                  icon: Icon(_obscureConfirmPassword ? Icons.visibility_off_rounded : Icons.visibility_rounded, color: authMuted),
                ),
                validator: (v) => (v != _passwordController.text) ? 'Şifreler eşleşmiyor' : null,
              ),
              const SizedBox(height: 18),
              _LegalConsentToggle(
                value: _legalConsentAccepted,
                onChanged: () => setState(() => _legalConsentAccepted = !_legalConsentAccepted),
                onTermsTap: _openTerms,
                onPrivacyTap: _openPrivacy,
              ),
              const SizedBox(height: 22),
              MassivePrimaryButton(
                label: 'Kayıt Ol',
                onPressed: _legalConsentAccepted ? _register : null,
                loading: _isLoading,
              ),
              const SizedBox(height: 18),
              const SocialDivider(),
              const SizedBox(height: 14),
              _isGoogleLoading
                  ? const SizedBox(height: 56, child: Center(child: CircularProgressIndicator(color: authEspresso)))
                  : SocialButton(label: 'Google ile Kayıt Ol', onPressed: _googleRegister, badgeText: 'G'),
              const SizedBox(height: 16),
              Center(
                child: Text.rich(
                  TextSpan(
                    text: 'Zaten hesabın var mı? ',
                    style: authText(size: 13, weight: FontWeight.w600, color: authMuted),
                    children: [
                      WidgetSpan(
                        child: GestureDetector(
                          onTap: () => context.go('/login'),
                          child: Text('Giriş Yap', style: authText(size: 13, weight: FontWeight.w800, color: authEspresso)),
                        ),
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

class _LegalConsentToggle extends StatelessWidget {
  const _LegalConsentToggle({
    required this.value,
    required this.onChanged,
    required this.onTermsTap,
    required this.onPrivacyTap,
  });

  final bool value;
  final VoidCallback onChanged;
  final VoidCallback onTermsTap;
  final VoidCallback onPrivacyTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onChanged,
      borderRadius: BorderRadius.circular(22),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: authWhite,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: value ? authCamel.withOpacity(.8) : authEspresso.withOpacity(.08),
            width: value ? 1.4 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: authEspresso.withOpacity(.04),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: 22,
              height: 22,
              margin: const EdgeInsets.only(top: 2),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                color: value ? authCamel : Colors.transparent,
                border: Border.all(
                  color: value ? authCamel : const Color(0xFFC4B9B1),
                  width: 1.8,
                ),
                boxShadow: value
                    ? [
                        BoxShadow(
                          color: authCamel.withOpacity(.22),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ]
                    : const [],
              ),
              child: value
                  ? const Icon(Icons.check_rounded, size: 15, color: Colors.white)
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Wrap(
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text(
                    ' ',
                    style: authText(
                      size: 12.5,
                      weight: FontWeight.w600,
                      color: authMuted,
                      height: 1.55,
                    ),
                  ),
                  GestureDetector(
                    onTap: onTermsTap,
                    child: Text(
                      'Kullanıcı Sözleşmesi',
                      style: authText(size: 12.5, weight: FontWeight.w800, color: authEspresso)
                          .copyWith(decoration: TextDecoration.underline),
                    ),
                  ),
                  Text(' ve ', style: authText(size: 12.5, weight: FontWeight.w600, color: authMuted, height: 1.55)),
                  GestureDetector(
                    onTap: onPrivacyTap,
                    child: Text(
                      'Gizlilik Politikası',
                      style: authText(size: 12.5, weight: FontWeight.w800, color: authEspresso)
                          .copyWith(decoration: TextDecoration.underline),
                    ),
                  ),
                  Text(
                    ' metinlerini okudum ve onaylıyorum.',
                    style: authText(
                      size: 12.5,
                      weight: FontWeight.w600,
                      color: authMuted,
                      height: 1.55,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
