import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../providers/auth_provider.dart';
import '../../providers/firebase_init_provider.dart';
import '../../utils/cities_tr.dart';
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

  CityTR? _selectedCity;

  static const _legalConsentVersion = 'v1.0';
  static final _termsUri = Uri.parse('https://fiyatradar.com/kullanim-kosullari');

  bool _isLoading = false;
  bool _isGoogleLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _legalConsentAccepted = false;

  static final RegExp _usernamePattern = RegExp(r'^[a-z0-9_]{3,20}$');

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
    if (_selectedCity == null) {
      _showError('Lütfen şehir seçin.');
      return;
    }
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
            cityCode: _selectedCity?.code,
            cityName: _selectedCity?.name,
            username: _usernameController.text.trim(),
            legalConsentVersion: _legalConsentVersion,
          );
      if (user == null) {
        _showError('Kullanıcı profili yüklenemedi.');
        return;
      }
      if (!mounted) return;
      context.go('/main');
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
        context.go('/main');
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

  Future<void> _openDisclosureSheet() async {
    if (!mounted) return;
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 28),
          decoration: BoxDecoration(
            color: authWhite,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            boxShadow: [
              BoxShadow(color: authEspresso.withOpacity(0.08), blurRadius: 24, offset: const Offset(0, -6)),
            ],
          ),
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 52,
                  height: 5,
                  margin: const EdgeInsets.only(bottom: 18),
                  decoration: BoxDecoration(
                    color: authEspresso.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                Text('Aydınlatma Metni', style: authText(size: 20, weight: FontWeight.w900, letterSpacing: -0.4)),
                const SizedBox(height: 12),
                Text(
                  'FiyatRadar; kimlik, iletişim ve konum bilgilerini hesap oluşturma, kişiselleştirme, güvenlik ve bildirim süreçlerini yürütmek amacıyla işler. Onayınızın zamanı Firestore üzerinde kayıt altına alınır.',
                  style: authText(size: 13, weight: FontWeight.w600, color: authMuted, height: 1.6),
                ),
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: authCamel.withOpacity(0.35)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: authCamel.withOpacity(0.06),
                    ),
                    child: Text('Tamam', style: authText(size: 14, weight: FontWeight.w800, color: authEspresso)),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
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
              _DropdownField<CityTR>(
                label: 'Şehir Seçiniz',
                hint: 'Şehir Seçiniz',
                icon: Icons.location_city_rounded,
                value: _selectedCity,
                items: kCitiesTR,
                itemLabel: (v) => v.name,
                onChanged: (v) => setState(() {
                  _selectedCity = v;
                }),
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
                  if (v == null || v.trim().isEmpty) return 'E-posta gerekli';
                  if (!v.contains('@')) return 'Geçerli bir e-posta girin';
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
                validator: (v) => (v == null || v.length < 6) ? 'Şifre en az 6 karakter olmalı' : null,
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
                onDisclosureTap: _openDisclosureSheet,
              ),
              const SizedBox(height: 22),
              MassivePrimaryButton(label: 'Kayıt Ol', onPressed: _register, loading: _isLoading),
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

class _DropdownField<T> extends StatelessWidget {
  const _DropdownField({
    required this.label,
    required this.hint,
    required this.icon,
    required this.value,
    required this.items,
    required this.itemLabel,
    required this.onChanged,
  });

  final String label;
  final String hint;
  final IconData icon;
  final T? value;
  final List<T> items;
  final String Function(T) itemLabel;
  final ValueChanged<T?> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 6),
          child: Text(label.toUpperCase(), style: authText(size: 11, weight: FontWeight.w800, letterSpacing: .5)),
        ),
        Container(
          height: 64,
          padding: const EdgeInsets.symmetric(horizontal: 18),
          decoration: BoxDecoration(
            color: authWhite,
            borderRadius: BorderRadius.circular(20),
            boxShadow: const [BoxShadow(color: Color.fromRGBO(28, 17, 8, .05), blurRadius: 18, offset: Offset(0, 6))],
          ),
          child: Row(
            children: [
              Icon(icon, color: authMuted, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<T>(
                    value: value,
                    isExpanded: true,
                    hint: Text(hint, style: authText(size: 15, weight: FontWeight.w500, color: const Color(0xFFB3ABA3))),
                    borderRadius: BorderRadius.circular(16),
                    icon: const Icon(Icons.keyboard_arrow_down_rounded, color: authMuted),
                    items: items.map((item) => DropdownMenuItem(value: item, child: Text(itemLabel(item), style: authText(size: 15, weight: FontWeight.w600)))).toList(),
                    onChanged: onChanged,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}


class _LegalConsentToggle extends StatelessWidget {
  const _LegalConsentToggle({
    required this.value,
    required this.onChanged,
    required this.onTermsTap,
    required this.onDisclosureTap,
  });

  final bool value;
  final VoidCallback onChanged;
  final VoidCallback onTermsTap;
  final VoidCallback onDisclosureTap;

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
                  Text("'", style: authText(size: 12.5, weight: FontWeight.w600, color: authMuted, height: 1.55)),
                  GestureDetector(
                    onTap: onTermsTap,
                    child: Text(
                      'Kullanım Koşulları',
                      style: authText(size: 12.5, weight: FontWeight.w800, color: authEspresso)
                          .copyWith(decoration: TextDecoration.underline),
                    ),
                  ),
                  Text(' ve ', style: authText(size: 12.5, weight: FontWeight.w600, color: authMuted, height: 1.55)),
                  GestureDetector(
                    onTap: onDisclosureTap,
                    child: Text(
                      'Aydınlatma Metni',
                      style: authText(size: 12.5, weight: FontWeight.w800, color: authEspresso)
                          .copyWith(decoration: TextDecoration.underline),
                    ),
                  ),
                  Text("'ni okudum, onaylıyorum.", style: authText(size: 12.5, weight: FontWeight.w600, color: authMuted, height: 1.55)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
