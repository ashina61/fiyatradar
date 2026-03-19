import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../providers/auth_provider.dart';
import '../../providers/firebase_init_provider.dart';
import '../main_screen.dart';
import 'widgets/auth_portal_widgets.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  static final RegExp _emailPattern = RegExp(r'^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$');

  bool _isLoading = false;
  bool _isGoogleLoading = false;
  bool _isResendingVerification = false;
  bool _obscurePassword = true;
  bool _rememberMe = false;
  bool _showResendVerification = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    if (!ref.read(firebaseInitializedProvider)) {
      _showError('Firebase bağlantısı kurulamadı. Lütfen internet bağlantınızı kontrol edin.');
      return;
    }

    setState(() => _isLoading = true);
    try {
      final user = await ref.read(authNotifierProvider.notifier).signIn(
            email: _emailController.text.trim(),
            password: _passwordController.text,
          );
      if (user == null) {
        _showError('Kullanıcı profili yüklenemedi.');
        return;
      }
      if (!mounted) return;
      setState(() => _showResendVerification = false);
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const MainScreen()),
        (route) => false,
      );
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        setState(() => _showResendVerification = e.code == 'email-not-verified');
      }
      _showError(ref.read(authServiceProvider).getErrorMessage(e));
    } catch (e) {
      _showError('Giriş yapılamadı: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _googleLogin() async {
    if (!ref.read(firebaseInitializedProvider)) {
      _showError('Firebase bağlantısı kurulamadı. Lütfen internet bağlantınızı kontrol edin.');
      return;
    }
    setState(() => _isGoogleLoading = true);
    try {
      final user = await ref.read(authNotifierProvider.notifier).signInWithGoogle();
      if (user != null && mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const MainScreen()),
          (route) => false,
        );
      }
    } on FirebaseAuthException catch (e) {
      _showError(ref.read(authServiceProvider).getErrorMessage(e));
    } catch (_) {
      _showError('Google ile giriş yapılamadı.');
    } finally {
      if (mounted) setState(() => _isGoogleLoading = false);
    }
  }


  Future<void> _resendVerificationEmail() async {
    if (_isResendingVerification) return;

    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      _showError('Doğrulama mailini tekrar göndermek için e-posta ve şifrenizi girin.');
      return;
    }

    setState(() => _isResendingVerification = true);
    try {
      await ref.read(authServiceProvider).resendVerificationEmail(
            email: email,
            password: password,
          );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Doğrulama maili tekrar gönderildi. Lütfen gelen kutunuzu kontrol edin.', style: authText(size: 12, weight: FontWeight.w700, color: Colors.white)),
          behavior: SnackBarBehavior.floating,
          backgroundColor: authEspresso,
        ),
      );
    } on FirebaseAuthException catch (e) {
      _showError(ref.read(authServiceProvider).getErrorMessage(e));
    } catch (e) {
      _showError('Doğrulama maili gönderilemedi: $e');
    } finally {
      if (mounted) setState(() => _isResendingVerification = false);
    }
  }

  void _showError(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), behavior: SnackBarBehavior.floating),
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
              AuthTopBackButton(onTap: () => context.go('/onboarding')),
              const SizedBox(height: 24),
              const AuthHeaderTexts(
                title: 'Hoş Geldin,\nRadar Avcısı.',
                subtitle: 'Veri ağına erişmek için kimliğini doğrula.',
              ),
              const SizedBox(height: 32),
              AuthInputField(
                label: 'E-Posta Adresi',
                hint: 'ajan@fiyatradar.com',
                icon: Icons.mail_outline_rounded,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                controller: _emailController,
                validator: (v) {
                  final email = (v ?? '').trim();
                  if (email.isEmpty) return 'Lütfen e-posta adresinizi girin';
                  if (!_emailPattern.hasMatch(email)) return 'Lütfen geçerli bir e-posta adresi girin.';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              AuthInputField(
                label: 'Şifre',
                hint: '••••••••',
                icon: Icons.lock_outline_rounded,
                obscureText: _obscurePassword,
                textInputAction: TextInputAction.done,
                onFieldSubmitted: (_) => _isLoading ? null : _login(),
                controller: _passwordController,
                suffix: IconButton(
                  onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                  icon: Icon(_obscurePassword ? Icons.visibility_off_rounded : Icons.visibility_rounded, color: authMuted),
                ),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Lütfen şifrenizi girin';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  RememberMeCheckbox(value: _rememberMe, onChanged: (v) => setState(() => _rememberMe = v)),
                  const Spacer(),
                  TextButton(
                    onPressed: () => context.push('/forgot-password'),
                    child: Text('Şifremi Unuttum', style: authText(size: 12, weight: FontWeight.w700, color: authCamel)),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              MassivePrimaryButton(label: 'Giriş Yap', onPressed: _login, loading: _isLoading),
              if (_showResendVerification) ...[
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton.icon(
                    onPressed: _isResendingVerification ? null : _resendVerificationEmail,
                    icon: _isResendingVerification
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2, color: authEspresso),
                          )
                        : const Icon(Icons.mark_email_read_outlined, size: 18, color: authEspresso),
                    label: Text(
                      'Doğrulama mailini tekrar gönder',
                      style: authText(size: 12, weight: FontWeight.w800, color: authEspresso),
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 24),
              const SocialDivider(),
              const SizedBox(height: 16),
              Row(
                children: [
                  const Expanded(child: SocialButton(label: 'Apple', onPressed: null, badgeText: '', disabled: true)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _isGoogleLoading
                        ? const SizedBox(height: 56, child: Center(child: CircularProgressIndicator(color: authEspresso)))
                        : SocialButton(label: 'Google', onPressed: _googleLogin, badgeText: 'G'),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              const Center(
                child: Text('APPLE ÇOK YAKINDA', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: authMuted)),
              ),
              const SizedBox(height: 26),
              Center(
                child: Text.rich(
                  TextSpan(
                    text: 'Ağda yeni misin? ',
                    style: authText(size: 13, weight: FontWeight.w600, color: authMuted),
                    children: [
                      WidgetSpan(
                        child: GestureDetector(
                          onTap: () => context.push('/register'),
                          child: Text('Kayıt Ol', style: authText(size: 13, weight: FontWeight.w800, color: authEspresso)),
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
