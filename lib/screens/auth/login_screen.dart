import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../providers/firebase_init_provider.dart';
import '../../services/auth_service.dart';
import '../../utils/theme.dart';
import '../main_screen.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _authService = AuthService();

  bool _isLoading = false;
  bool _isGoogleLoading = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    if (!firebaseInitialized) {
      _showErrorSnackBar(
        'Firebase bağlantısı kurulamadı. Lütfen internet bağlantınızı kontrol edin.',
      );
      setState(() => _isLoading = false);
      return;
    }

    try {
      await _authService.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const MainScreen()),
      );
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      _showErrorSnackBar(_authService.getErrorMessage(e));
    } catch (e) {
      if (!mounted) return;
      _showErrorSnackBar('Giriş yapılamadı: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _signInWithGoogle() async {
    if (!firebaseInitialized) {
      _showErrorSnackBar(
        'Firebase bağlantısı kurulamadı. Lütfen internet bağlantınızı kontrol edin.',
      );
      return;
    }

    setState(() => _isGoogleLoading = true);

    try {
      final user = await _authService.signInWithGoogle();

      if (user != null && mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const MainScreen()),
        );
      } else if (mounted) {
        setState(() => _isGoogleLoading = false);
      }
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      _showErrorSnackBar(_authService.getErrorMessage(e));
      setState(() => _isGoogleLoading = false);
    } catch (e) {
      if (!mounted) return;
      var errorMessage = 'Google ile giriş yapılamadı.';
      if (e.toString().contains('ApiException: 10')) {
        errorMessage =
            'Google giriş yapılandırması eksik. Firebase Console\'dan SHA-1 parmak izi ekleyin.';
      } else if (e.toString().contains('network')) {
        errorMessage = 'Bağlantı hatası. İnternet bağlantınızı kontrol edin.';
      }
      _showErrorSnackBar(errorMessage);
      setState(() => _isGoogleLoading = false);
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.sm),
        ),
        margin: const EdgeInsets.all(AppSpacing.md),
        duration: const Duration(seconds: 4),
      ),
    );
  }

  void _showForgotPasswordDialog() {
    final emailController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
        title: const Row(
          children: [
            Icon(Icons.lock_reset, color: AppColors.primary),
            SizedBox(width: AppSpacing.sm),
            Text('Şifremi Unuttum'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'E-posta adresinizi girin, size şifre sıfırlama bağlantısı gönderelim.',
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: AppSpacing.md),
            TextField(
              controller: emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                hintText: 'E-posta adresiniz',
                prefixIcon: Icon(Icons.email_outlined),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (emailController.text.isEmpty) return;

              try {
                await _authService.resetPassword(emailController.text.trim());
                if (!mounted) return;
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('Şifre sıfırlama e-postası gönderildi!'),
                    backgroundColor: AppColors.success,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                    ),
                  ),
                );
              } catch (e) {
                Navigator.pop(ctx);
                _showErrorSnackBar('E-posta gönderilemedi: $e');
              }
            },
            child: const Text('Gönder'),
          ),
        ],
      ),
    );
  }

  void _navigateToRegister() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const RegisterScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: _backgroundGradient(theme),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: EdgeInsets.only(
              left: AppSpacing.lg,
              right: AppSpacing.lg,
              top: AppSpacing.md,
              bottom: MediaQuery.of(context).viewInsets.bottom + AppSpacing.lg,
            ),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 460),
              child: Center(
                child: Column(
                  children: [
                    const SizedBox(height: AppSpacing.md),
                    _buildHeader(theme),
                    const SizedBox(height: AppSpacing.xl),
                    _buildAuthCard(theme),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  LinearGradient _backgroundGradient(ThemeData theme) {
    final scheme = theme.colorScheme;
    return LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        scheme.primaryContainer.withOpacity(0.18),
        scheme.surfaceVariant.withOpacity(0.35),
        scheme.surface,
      ],
    );
  }

  Widget _buildHeader(ThemeData theme) {

    return Column(
      children: [
        Container(
          width: 96,
          height: 96,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(30),
            color: theme.colorScheme.surface,
            border: Border.all(color: theme.colorScheme.outlineVariant),
            boxShadow: [
              BoxShadow(
                color: theme.colorScheme.primary.withOpacity(0.12),
                blurRadius: 26,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: Image.asset('assets/images/app_logo.png', fit: BoxFit.contain),
        ),
        const SizedBox(height: AppSpacing.md),
        Text(
          'FiyatRadar\'a hoş geldin',
          textAlign: TextAlign.center,
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          'Market fiyatlarını takip et, doğrula ve puan kazan.',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildAuthCard(ThemeData theme) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: theme.colorScheme.outlineVariant),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.onSurface.withOpacity(0.06),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Form(
        key: _formKey,
        autovalidateMode: AutovalidateMode.onUserInteraction,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildGoogleButton(theme),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                const Expanded(child: Divider()),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
                  child: Text(
                    'veya e-posta ile',
                    style: theme.textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
                  ),
                ),
                const Expanded(child: Divider()),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            TextFormField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                labelText: 'E-posta',
                prefixIcon: Icon(Icons.email_outlined),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Lütfen e-posta adresinizi girin';
                }
                if (!value.contains('@')) {
                  return 'Geçerli bir e-posta girin';
                }
                return null;
              },
            ),
            const SizedBox(height: AppSpacing.md),
            TextFormField(
              controller: _passwordController,
              obscureText: _obscurePassword,
              textInputAction: TextInputAction.done,
              onFieldSubmitted: (_) => _isLoading ? null : _login(),
              decoration: InputDecoration(
                labelText: 'Şifre',
                prefixIcon: const Icon(Icons.lock_outline_rounded),
                suffixIcon: IconButton(
                  onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                  icon: Icon(_obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined),
                ),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Lütfen şifrenizi girin';
                }
                if (value.length < 6) {
                  return 'Şifre en az 6 karakter olmalıdır';
                }
                return null;
              },
            ),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: _showForgotPasswordDialog,
                child: const Text('Şifremi unuttum'),
              ),
            ),
            SizedBox(
              height: 52,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _login,
                child: _isLoading
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(strokeWidth: 2.4, color: Colors.white),
                      )
                    : const Text('Giriş Yap'),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('Hesabın yok mu?', style: TextStyle(color: AppColors.textSecondary)),
                TextButton(onPressed: _navigateToRegister, child: const Text('Kayıt Ol')),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGoogleButton(ThemeData theme) {
    return SizedBox(
      height: 52,
      child: OutlinedButton(
        onPressed: _isGoogleLoading ? null : _signInWithGoogle,
        style: OutlinedButton.styleFrom(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.lg)),
          side: BorderSide(color: theme.colorScheme.outlineVariant),
        ),
        child: _isGoogleLoading
            ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2.2))
            : const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.login_rounded, size: 18),
                  SizedBox(width: 8),
                  Text('Google ile giriş yap'),
                ],
              ),
      ),
    );
  }
}
