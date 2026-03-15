import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../providers/auth_provider.dart';
import '../../providers/firebase_init_provider.dart';
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

  bool _isLoading = false;
  bool _isGoogleLoading = false;
  bool _obscurePassword = true;
  bool _rememberMe = false;

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
      await ref.read(authServiceProvider).signInWithEmailAndPassword(
            email: _emailController.text.trim(),
            password: _passwordController.text,
          );
      if (!mounted) return;
      context.go('/main');
    } on FirebaseAuthException catch (e) {
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
      final user = await ref.read(authServiceProvider).signInWithGoogle();
      if (user != null && mounted) {
        context.go('/main');
      }
    } on FirebaseAuthException catch (e) {
      _showError(ref.read(authServiceProvider).getErrorMessage(e));
    } catch (_) {
      _showError('Google ile giriş yapılamadı.');
    } finally {
      if (mounted) setState(() => _isGoogleLoading = false);
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
                  if (v == null || v.trim().isEmpty) return 'Lütfen e-posta adresinizi girin';
                  if (!v.contains('@')) return 'Geçerli bir e-posta girin';
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
