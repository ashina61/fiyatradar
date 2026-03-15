import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../providers/auth_provider.dart';
import '../../providers/firebase_init_provider.dart';
import '../../utils/cities_tr.dart';
import 'widgets/auth_portal_widgets.dart';

class DistrictTR {
  const DistrictTR({required this.name});
  final String name;
}

const Map<String, List<DistrictTR>> kDistrictsByCityCode = {
  '34': [DistrictTR(name: 'Kadıköy'), DistrictTR(name: 'Beşiktaş'), DistrictTR(name: 'Üsküdar')],
  '06': [DistrictTR(name: 'Çankaya'), DistrictTR(name: 'Keçiören'), DistrictTR(name: 'Yenimahalle')],
  '35': [DistrictTR(name: 'Konak'), DistrictTR(name: 'Karşıyaka'), DistrictTR(name: 'Bornova')],
};

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
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  CityTR? _selectedCity;
  String? _selectedDistrict;

  bool _isLoading = false;
  bool _isGoogleLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  List<DistrictTR> get _districts => kDistrictsByCityCode[_selectedCity?.code] ?? const [];

  @override
  void dispose() {
    _nameController.dispose();
    _inviteController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCity == null || _selectedDistrict == null) {
      _showError('Lütfen şehir ve ilçe seçin.');
      return;
    }
    if (!ref.read(firebaseInitializedProvider)) {
      _showError('Firebase bağlantısı kurulamadı. Lütfen internet bağlantınızı kontrol edin.');
      return;
    }

    setState(() => _isLoading = true);
    try {
      await ref.read(authServiceProvider).registerWithEmailAndPassword(
            email: _emailController.text.trim(),
            password: _passwordController.text,
            name: _nameController.text.trim(),
            inviteCode: _inviteController.text.trim(),
            cityCode: _selectedCity?.code,
            cityName: _selectedCity?.name,
            district: _selectedDistrict,
          );
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

    setState(() => _isGoogleLoading = true);
    try {
      final user = await ref.read(authServiceProvider).signInWithGoogle();
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
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), behavior: SnackBarBehavior.floating));
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
                  _selectedDistrict = null;
                }),
              ),
              const SizedBox(height: 14),
              _DropdownField<String>(
                label: 'İlçe',
                hint: 'İlçe',
                icon: Icons.map_outlined,
                value: _selectedDistrict,
                items: _districts.map((e) => e.name).toList(),
                itemLabel: (v) => v,
                onChanged: (v) => setState(() => _selectedDistrict = v),
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
              const SizedBox(height: 10),
              Center(
                child: Text(
                  "Kayıt olarak Kullanım Koşulları ve Gizlilik Politikası'nı kabul etmiş olursunuz.",
                  textAlign: TextAlign.center,
                  style: authText(size: 10, weight: FontWeight.w500, color: authMuted, height: 1.5),
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
