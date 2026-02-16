import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../main.dart';
import '../../services/auth_service.dart';
import '../../utils/cities_tr.dart';
import '../../utils/theme.dart';
import '../main_screen.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _authService = AuthService();

  bool _isLoading = false;
  bool _isGoogleLoading = false;
  bool _obscurePassword = true;
  CityTR? _selectedCity;

  late final AnimationController _slideController;
  late final AnimationController _fadeController;
  late final Animation<Offset> _slideAnimation;
  late final Animation<double> _fadeAnimation;
  late final Animation<double> _iconFadeAnimation;
  late final Animation<double> _titleFadeAnimation;

  @override
  void initState() {
    super.initState();

    _slideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 520),
    );

    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 720),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.08),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _slideController,
        curve: Curves.easeOutCubic,
      ),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _fadeController,
        curve: const Interval(0.2, 1.0, curve: Curves.easeOutCubic),
      ),
    );

    _iconFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _fadeController,
        curve: const Interval(0.0, 0.55, curve: Curves.easeOut),
      ),
    );

    _titleFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _fadeController,
        curve: const Interval(0.12, 0.7, curve: Curves.easeOut),
      ),
    );

    _fadeController.forward();
    _slideController.forward();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _slideController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    if (!firebaseInitialized) {
      _showErrorSnackBar(
        'Firebase baglantisi kurulamadi. Lutfen internet baglantinizi kontrol edin.',
      );
      setState(() => _isLoading = false);
      return;
    }

    try {
      await _authService.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        cityCode: _selectedCity?.code,
        cityName: _selectedCity?.name,
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
      _showErrorSnackBar('Giris yapilamadi: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _signInWithGoogle() async {
    if (!firebaseInitialized) {
      _showErrorSnackBar(
        'Firebase baglantisi kurulamadi. Lutfen internet baglantinizi kontrol edin.',
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
      var errorMessage = 'Google ile giris yapilamadi.';
      if (e.toString().contains('ApiException: 10')) {
        errorMessage =
            'Google giris yapilandirmasi eksik. Firebase Console\'dan SHA-1 parmak izi ekleyin.';
      } else if (e.toString().contains('network')) {
        errorMessage = 'Baglanti hatasi. Internet baglantinizi kontrol edin.';
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
            Text('Sifremi Unuttum'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'E-posta adresinizi girin, size sifre sifirlama baglantisi gonderelim.',
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
            child: const Text('Iptal'),
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
                    content: const Text('Sifre sifirlama e-postasi gonderildi!'),
                    backgroundColor: AppColors.success,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                    ),
                  ),
                );
              } catch (e) {
                Navigator.pop(ctx);
                _showErrorSnackBar('E-posta gonderilemedi: $e');
              }
            },
            child: const Text('Gonder'),
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
    final colorScheme = theme.colorScheme;

    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: EdgeInsets.only(
                left: AppSpacing.lg,
                right: AppSpacing.lg,
                top: AppSpacing.lg,
                bottom: MediaQuery.of(context).viewInsets.bottom + AppSpacing.lg,
              ),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight - AppSpacing.lg * 2,
                ),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 420),
                    child: SlideTransition(
                      position: _slideAnimation,
                      child: FadeTransition(
                        opacity: _fadeAnimation,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
            _buildHero(theme),
            const SizedBox(height: AppSpacing.xl),
                            Material(
                              color: theme.cardColor,
                              elevation: 0,
                              shadowColor: Colors.transparent,
                              borderRadius: BorderRadius.circular(AppRadius.xxl),
                              child: Padding(
                                padding: const EdgeInsets.all(AppSpacing.lg),
                                child: Form(
                                  key: _formKey,
                                  autovalidateMode:
                                      AutovalidateMode.onUserInteraction,
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.stretch,
                                    children: [
                                      Text(
                                        'Hos Geldiniz',
                                        style: theme.textTheme.headlineMedium,
                                      ),
                                      const SizedBox(height: AppSpacing.xs),
                                      Text(
                                        'Devam etmek icin hesabiniza giris yapin.',
                                        style:
                                            theme.textTheme.bodyMedium?.copyWith(
                                          color:
                                              theme.textTheme.bodyMedium?.color
                                                  ?.withOpacity(0.72),
                                        ),
                                      ),
                                      const SizedBox(height: AppSpacing.lg),
                                      _buildGoogleButton(theme),
                                      const SizedBox(height: AppSpacing.md),
                                      Row(
                                        children: [
                                          Expanded(
                                            child: Divider(
                                              color: colorScheme.outlineVariant,
                                            ),
                                          ),
                                          Padding(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: AppSpacing.sm,
                                            ),
                                            child: Text(
                                              'veya e-posta ile',
                                              style: theme.textTheme.bodySmall
                                                  ?.copyWith(
                                                color: theme.hintColor,
                                              ),
                                            ),
                                          ),
                                          Expanded(
                                            child: Divider(
                                              color: colorScheme.outlineVariant,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: AppSpacing.md),
                                      TextFormField(
                                        controller: _emailController,
                                        keyboardType: TextInputType.emailAddress,
                                        textInputAction: TextInputAction.next,
                                        autofillHints: const [
                                          AutofillHints.username,
                                          AutofillHints.email,
                                        ],
                                        decoration: const InputDecoration(
                                          labelText: 'E-posta',
                                          helperText: 'ornek@eposta.com',
                                          prefixIcon: Icon(Icons.email_outlined),
                                        ),
                                        validator: (value) {
                                          if (value == null || value.isEmpty) {
                                            return 'Lutfen e-posta adresinizi girin';
                                          }
                                          if (!value.contains('@')) {
                                            return 'Gecerli bir e-posta girin';
                                          }
                                          return null;
                                        },
                                      ),
                                      const SizedBox(height: 14),
                                      DropdownButtonFormField<CityTR>(
                                        value: _selectedCity,
                                        items: kCitiesTR.map((city) => DropdownMenuItem<CityTR>(value: city, child: Text(city.name))).toList(),
                                        onChanged: (value) => setState(() => _selectedCity = value),
                                        decoration: const InputDecoration(
                                          labelText: 'Şehir',
                                          prefixIcon: Icon(Icons.location_city_outlined),
                                        ),
                                        validator: (value) => value == null ? 'Lütfen şehir seçin' : null,
                                      ),
                                      const SizedBox(height: 14),
                                      TextFormField(
                                        controller: _passwordController,
                                        obscureText: _obscurePassword,
                                        textInputAction: TextInputAction.done,
                                        autofillHints: const [
                                          AutofillHints.password,
                                        ],
                                        onFieldSubmitted: (_) {
                                          if (!_isLoading) _login();
                                        },
                                        decoration: InputDecoration(
                                          labelText: 'Sifre',
                                          helperText:
                                              'En az 6 karakter girmelisiniz',
                                          prefixIcon:
                                              const Icon(Icons.lock_outline),
                                          suffixIcon: IconButton(
                                            icon: Icon(
                                              _obscurePassword
                                                  ? Icons.visibility_outlined
                                                  : Icons.visibility_off_outlined,
                                            ),
                                            onPressed: () {
                                              setState(() {
                                                _obscurePassword =
                                                    !_obscurePassword;
                                              });
                                            },
                                          ),
                                        ),
                                        validator: (value) {
                                          if (value == null || value.isEmpty) {
                                            return 'Lutfen sifrenizi girin';
                                          }
                                          if (value.length < 6) {
                                            return 'Sifre en az 6 karakter olmali';
                                          }
                                          return null;
                                        },
                                      ),
                                      Align(
                                        alignment: Alignment.centerRight,
                                        child: TextButton(
                                          onPressed: _showForgotPasswordDialog,
                                          style: TextButton.styleFrom(
                                            visualDensity:
                                                VisualDensity.compact,
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: AppSpacing.xs,
                                            ),
                                          ),
                                          child: const Text(
                                            'Sifremi Unuttum',
                                            style: TextStyle(fontSize: 12),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: AppSpacing.sm),
                                      SizedBox(
                                        height: 56,
                                        child: ElevatedButton(
                                          onPressed: _isLoading ? null : _login,
                                          style: ElevatedButton.styleFrom(
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(
                                                AppRadius.xl,
                                              ),
                                            ),
                                          ),
                                          child: _isLoading
                                              ? const Row(
                                                  mainAxisSize:
                                                      MainAxisSize.min,
                                                  children: [
                                                    SizedBox(
                                                      height: 20,
                                                      width: 20,
                                                      child:
                                                          CircularProgressIndicator(
                                                        strokeWidth: 2.2,
                                                        color: Colors.white,
                                                      ),
                                                    ),
                                                    SizedBox(
                                                      width: AppSpacing.sm,
                                                    ),
                                                    Text('Giris Yapiliyor...'),
                                                  ],
                                                )
                                              : const Text('Giris Yap'),
                                        ),
                                      ),
                                      const SizedBox(height: AppSpacing.md),
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Text(
                                            'Hesabiniz yok mu? ',
                                            style: theme.textTheme.bodyMedium
                                                ?.copyWith(
                                              color: theme.hintColor,
                                            ),
                                          ),
                                          GestureDetector(
                                            onTap: _navigateToRegister,
                                            child: Text(
                                              'Kayit Ol',
                                              style: theme.textTheme.bodyMedium
                                                  ?.copyWith(
                                                color: AppColors.primary,
                                                fontWeight: FontWeight.w700,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildHero(ThemeData theme) {
    final colorScheme = theme.colorScheme;

    return FadeTransition(
      opacity: _titleFadeAnimation,
      child: Column(
        children: [
          FadeTransition(
            opacity: _iconFadeAnimation,
            child: Container(
              padding: const EdgeInsets.all(AppSpacing.sm),
              decoration: BoxDecoration(
                color: colorScheme.surface,
                borderRadius: BorderRadius.circular(AppRadius.xl),
                border: Border.all(color: colorScheme.outline.withOpacity(0.7)),
              ),
              child: Image.asset(
                'assets/images/app_logo.png',
                width: 112,
                height: 112,
                fit: BoxFit.contain,
                filterQuality: FilterQuality.high,
                gaplessPlayback: true,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'FiyatRadar',
            textAlign: TextAlign.center,
            style: theme.textTheme.headlineLarge?.copyWith(
              fontWeight: FontWeight.w700,
              letterSpacing: 0.2,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Market fiyatlarini akilli sekilde takip edin',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.textTheme.bodyMedium?.color?.withOpacity(0.68),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGoogleButton(ThemeData theme) {
    return SizedBox(
      height: 54,
      child: OutlinedButton(
        onPressed: _isGoogleLoading ? null : _signInWithGoogle,
        style: OutlinedButton.styleFrom(
          backgroundColor: theme.colorScheme.surface,
          side: BorderSide(color: theme.colorScheme.outlineVariant),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.lg),
          ),
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
        ),
        child: _isGoogleLoading
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(strokeWidth: 2.2),
              )
            : Row(
                children: [
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(AppRadius.xs),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      'G',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        foreground: Paint()
                          ..shader = const LinearGradient(
                            colors: [
                              Color(0xFF4285F4),
                              Color(0xFF34A853),
                              Color(0xFFFBBC05),
                              Color(0xFFEA4335),
                            ],
                          ).createShader(const Rect.fromLTWH(0, 0, 24, 24)),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Text(
                      'Google ile giris yap',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 24 + AppSpacing.md),
                ],
              ),
      ),
    );
  }
}
