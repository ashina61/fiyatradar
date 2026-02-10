import 'dart:math' as math;

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../main.dart';
import '../../services/auth_service.dart';
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

  // Main stagger animation
  late final AnimationController _staggerController;
  // Floating particles
  late final AnimationController _particleController;
  // Logo pulse
  late final AnimationController _pulseController;
  // Button shimmer
  late final AnimationController _shimmerController;

  // Staggered animations
  late final Animation<double> _logoScale;
  late final Animation<double> _logoOpacity;
  late final Animation<Offset> _titleSlide;
  late final Animation<double> _titleOpacity;
  late final Animation<Offset> _cardSlide;
  late final Animation<double> _cardOpacity;
  late final Animation<double> _googleBtnOpacity;
  late final Animation<Offset> _googleBtnSlide;
  late final Animation<double> _dividerScale;
  late final Animation<double> _emailOpacity;
  late final Animation<Offset> _emailSlide;
  late final Animation<double> _passwordOpacity;
  late final Animation<Offset> _passwordSlide;
  late final Animation<double> _loginBtnOpacity;
  late final Animation<double> _loginBtnScale;
  late final Animation<double> _footerOpacity;

  @override
  void initState() {
    super.initState();

    _staggerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );

    _particleController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);

    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat();

    // Logo: 0.0 - 0.30
    _logoScale = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(
        parent: _staggerController,
        curve: const Interval(0.0, 0.30, curve: Curves.elasticOut),
      ),
    );
    _logoOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _staggerController,
        curve: const Interval(0.0, 0.20, curve: Curves.easeOut),
      ),
    );

    // Title: 0.12 - 0.35
    _titleSlide = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _staggerController,
        curve: const Interval(0.12, 0.35, curve: Curves.easeOutCubic),
      ),
    );
    _titleOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _staggerController,
        curve: const Interval(0.12, 0.30, curve: Curves.easeOut),
      ),
    );

    // Card: 0.22 - 0.45
    _cardSlide = Tween<Offset>(
      begin: const Offset(0, 0.15),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _staggerController,
        curve: const Interval(0.22, 0.45, curve: Curves.easeOutCubic),
      ),
    );
    _cardOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _staggerController,
        curve: const Interval(0.22, 0.40, curve: Curves.easeOut),
      ),
    );

    // Google button: 0.32 - 0.50
    _googleBtnOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _staggerController,
        curve: const Interval(0.32, 0.48, curve: Curves.easeOut),
      ),
    );
    _googleBtnSlide = Tween<Offset>(
      begin: const Offset(0, 0.2),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _staggerController,
        curve: const Interval(0.32, 0.50, curve: Curves.easeOutCubic),
      ),
    );

    // Divider: 0.40 - 0.55
    _dividerScale = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _staggerController,
        curve: const Interval(0.40, 0.55, curve: Curves.easeOutCubic),
      ),
    );

    // Email field: 0.45 - 0.60
    _emailOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _staggerController,
        curve: const Interval(0.45, 0.58, curve: Curves.easeOut),
      ),
    );
    _emailSlide = Tween<Offset>(
      begin: const Offset(-0.05, 0),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _staggerController,
        curve: const Interval(0.45, 0.60, curve: Curves.easeOutCubic),
      ),
    );

    // Password field: 0.52 - 0.67
    _passwordOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _staggerController,
        curve: const Interval(0.52, 0.65, curve: Curves.easeOut),
      ),
    );
    _passwordSlide = Tween<Offset>(
      begin: const Offset(-0.05, 0),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _staggerController,
        curve: const Interval(0.52, 0.67, curve: Curves.easeOutCubic),
      ),
    );

    // Login button: 0.60 - 0.80
    _loginBtnOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _staggerController,
        curve: const Interval(0.60, 0.75, curve: Curves.easeOut),
      ),
    );
    _loginBtnScale = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(
        parent: _staggerController,
        curve: const Interval(0.60, 0.80, curve: Curves.elasticOut),
      ),
    );

    // Footer: 0.70 - 0.90
    _footerOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _staggerController,
        curve: const Interval(0.70, 0.90, curve: Curves.easeOut),
      ),
    );

    _staggerController.forward();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _staggerController.dispose();
    _particleController.dispose();
    _pulseController.dispose();
    _shimmerController.dispose();
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
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white, size: 20),
            const SizedBox(width: AppSpacing.sm),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
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
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            const RegisterScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: CurvedAnimation(
              parent: animation,
              curve: Curves.easeInOut,
            ),
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0.03, 0),
                end: Offset.zero,
              ).animate(CurvedAnimation(
                parent: animation,
                curve: Curves.easeOutCubic,
              )),
              child: child,
            ),
          );
        },
        transitionDuration: const Duration(milliseconds: 400),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final size = MediaQuery.of(context).size;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: isDark
          ? SystemUiOverlayStyle.light
          : SystemUiOverlayStyle.dark,
      child: Scaffold(
        body: Stack(
          children: [
            // Animated gradient background
            _AnimatedGradientBackground(
              controller: _particleController,
              isDark: isDark,
            ),

            // Floating orbs
            ..._buildFloatingOrbs(size, isDark),

            // Main content
            SafeArea(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return SingleChildScrollView(
                    padding: EdgeInsets.only(
                      left: AppSpacing.xl,
                      right: AppSpacing.xl,
                      top: AppSpacing.lg,
                      bottom: MediaQuery.of(context).viewInsets.bottom +
                          AppSpacing.lg,
                    ),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight: constraints.maxHeight - AppSpacing.lg * 2,
                      ),
                      child: Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 420),
                          child: AnimatedBuilder(
                            animation: _staggerController,
                            builder: (context, _) => Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                _buildAnimatedLogo(theme, isDark),
                                const SizedBox(height: AppSpacing.xl + 8),
                                _buildGlassCard(theme, isDark),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildFloatingOrbs(Size size, bool isDark) {
    return List.generate(5, (index) {
      final random = math.Random(index * 42);
      final startX = random.nextDouble() * size.width;
      final startY = random.nextDouble() * size.height;
      final orbSize = 60.0 + random.nextDouble() * 120;

      return AnimatedBuilder(
        animation: _particleController,
        builder: (context, child) {
          final progress = (_particleController.value + index * 0.2) % 1.0;
          final dx = math.sin(progress * 2 * math.pi) * 30;
          final dy = math.cos(progress * 2 * math.pi + index) * 20;

          return Positioned(
            left: startX + dx,
            top: startY + dy,
            child: Container(
              width: orbSize,
              height: orbSize,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    (index.isEven
                            ? AppColors.primary
                            : AppColors.accent)
                        .withOpacity(isDark ? 0.06 : 0.04),
                    (index.isEven
                            ? AppColors.primaryLight
                            : AppColors.secondary)
                        .withOpacity(0.0),
                  ],
                ),
              ),
            ),
          );
        },
      );
    });
  }

  Widget _buildAnimatedLogo(ThemeData theme, bool isDark) {
    return Opacity(
      opacity: _logoOpacity.value,
      child: Transform.scale(
        scale: _logoScale.value,
        child: Column(
          children: [
            // Pulsing logo container
            AnimatedBuilder(
              animation: _pulseController,
              builder: (context, child) {
                final pulseValue = _pulseController.value;
                return Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(32),
                    color: isDark
                        ? AppColors.surfaceDark.withOpacity(0.7)
                        : Colors.white.withOpacity(0.85),
                    border: Border.all(
                      color: AppColors.primary
                          .withOpacity(0.15 + pulseValue * 0.1),
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary
                            .withOpacity(0.08 + pulseValue * 0.06),
                        blurRadius: 30 + pulseValue * 10,
                        spreadRadius: pulseValue * 4,
                      ),
                      BoxShadow(
                        color: AppColors.accent
                            .withOpacity(0.04 + pulseValue * 0.03),
                        blurRadius: 50,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Image.asset(
                    'assets/images/app_logo.png',
                    width: 88,
                    height: 88,
                    fit: BoxFit.contain,
                    filterQuality: FilterQuality.high,
                    gaplessPlayback: true,
                  ),
                );
              },
            ),
            const SizedBox(height: AppSpacing.lg),

            // Title with slide
            SlideTransition(
              position: _titleSlide,
              child: Opacity(
                opacity: _titleOpacity.value,
                child: Column(
                  children: [
                    ShaderMask(
                      shaderCallback: (bounds) => const LinearGradient(
                        colors: [
                          AppColors.primaryDark,
                          AppColors.primary,
                          AppColors.accent,
                        ],
                      ).createShader(bounds),
                      child: Text(
                        'FiyatRadar',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.displayMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.5,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs + 2),
                    Text(
                      'Market fiyatlarini akilli sekilde takip edin',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.textTheme.bodyMedium?.color
                            ?.withOpacity(0.6),
                        letterSpacing: 0.2,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGlassCard(ThemeData theme, bool isDark) {
    final colorScheme = theme.colorScheme;

    return SlideTransition(
      position: _cardSlide,
      child: Opacity(
        opacity: _cardOpacity.value,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            color: isDark
                ? AppColors.surfaceDark.withOpacity(0.75)
                : Colors.white.withOpacity(0.88),
            border: Border.all(
              color: isDark
                  ? AppColors.outlineDark.withOpacity(0.4)
                  : AppColors.outline.withOpacity(0.5),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(isDark ? 0.3 : 0.06),
                blurRadius: 40,
                offset: const Offset(0, 12),
              ),
              BoxShadow(
                color: AppColors.primary.withOpacity(0.03),
                blurRadius: 80,
                offset: const Offset(0, 20),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.xl,
              vertical: AppSpacing.xl + 4,
            ),
            child: Form(
              key: _formKey,
              autovalidateMode: AutovalidateMode.onUserInteraction,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Welcome text
                  Text(
                    'Hos Geldiniz',
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xxs),
                  Text(
                    'Devam etmek icin hesabiniza giris yapin.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.textTheme.bodyMedium?.color
                          ?.withOpacity(0.65),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),

                  // Google button with animation
                  SlideTransition(
                    position: _googleBtnSlide,
                    child: Opacity(
                      opacity: _googleBtnOpacity.value,
                      child: _buildGoogleButton(theme),
                    ),
                  ),

                  const SizedBox(height: AppSpacing.lg),

                  // Animated divider
                  Transform.scale(
                    scaleX: _dividerScale.value,
                    child: Row(
                      children: [
                        Expanded(
                          child: Container(
                            height: 1,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  colorScheme.outlineVariant.withOpacity(0.0),
                                  colorScheme.outlineVariant,
                                ],
                              ),
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.md,
                          ),
                          child: Text(
                            'veya e-posta ile',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.hintColor,
                              fontSize: 12,
                            ),
                          ),
                        ),
                        Expanded(
                          child: Container(
                            height: 1,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  colorScheme.outlineVariant,
                                  colorScheme.outlineVariant.withOpacity(0.0),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: AppSpacing.lg),

                  // Email field
                  SlideTransition(
                    position: _emailSlide,
                    child: Opacity(
                      opacity: _emailOpacity.value,
                      child: TextFormField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.next,
                        autofillHints: const [
                          AutofillHints.username,
                          AutofillHints.email,
                        ],
                        decoration: InputDecoration(
                          labelText: 'E-posta',
                          hintText: 'ornek@eposta.com',
                          prefixIcon: Container(
                            margin: const EdgeInsets.only(left: 12, right: 8),
                            child: const Icon(Icons.email_outlined, size: 20),
                          ),
                          prefixIconConstraints: const BoxConstraints(
                            minWidth: 44,
                            minHeight: 44,
                          ),
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
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Password field
                  SlideTransition(
                    position: _passwordSlide,
                    child: Opacity(
                      opacity: _passwordOpacity.value,
                      child: TextFormField(
                        controller: _passwordController,
                        obscureText: _obscurePassword,
                        textInputAction: TextInputAction.done,
                        autofillHints: const [AutofillHints.password],
                        onFieldSubmitted: (_) {
                          if (!_isLoading) _login();
                        },
                        decoration: InputDecoration(
                          labelText: 'Sifre',
                          hintText: 'En az 6 karakter',
                          prefixIcon: Container(
                            margin: const EdgeInsets.only(left: 12, right: 8),
                            child: const Icon(Icons.lock_outline, size: 20),
                          ),
                          prefixIconConstraints: const BoxConstraints(
                            minWidth: 44,
                            minHeight: 44,
                          ),
                          suffixIcon: IconButton(
                            icon: AnimatedSwitcher(
                              duration: const Duration(milliseconds: 200),
                              child: Icon(
                                _obscurePassword
                                    ? Icons.visibility_outlined
                                    : Icons.visibility_off_outlined,
                                key: ValueKey(_obscurePassword),
                                size: 20,
                              ),
                            ),
                            onPressed: () {
                              setState(() {
                                _obscurePassword = !_obscurePassword;
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
                    ),
                  ),

                  // Forgot password
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: _showForgotPasswordDialog,
                      style: TextButton.styleFrom(
                        visualDensity: VisualDensity.compact,
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.xs,
                          vertical: AppSpacing.xs,
                        ),
                      ),
                      child: const Text(
                        'Sifremi Unuttum',
                        style: TextStyle(fontSize: 12),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),

                  // Login button with shimmer
                  Opacity(
                    opacity: _loginBtnOpacity.value,
                    child: Transform.scale(
                      scale: _loginBtnScale.value,
                      child: _buildLoginButton(theme, isDark),
                    ),
                  ),

                  const SizedBox(height: AppSpacing.lg),

                  // Register link
                  Opacity(
                    opacity: _footerOpacity.value,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Hesabiniz yok mu? ',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.hintColor,
                          ),
                        ),
                        GestureDetector(
                          onTap: _navigateToRegister,
                          child: Text(
                            'Kayit Ol',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoginButton(ThemeData theme, bool isDark) {
    return SizedBox(
      height: 56,
      child: AnimatedBuilder(
        animation: _shimmerController,
        builder: (context, child) {
          return Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppRadius.xl),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColors.primary,
                  AppColors.primaryLight,
                  AppColors.primary,
                ],
                stops: [
                  0.0,
                  (_shimmerController.value - 0.3).clamp(0.0, 1.0),
                  1.0,
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withOpacity(0.35),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
                BoxShadow(
                  color: AppColors.primary.withOpacity(0.15),
                  blurRadius: 30,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: child,
          );
        },
        child: ElevatedButton(
          onPressed: _isLoading ? null : _login,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.xl),
            ),
          ),
          child: _isLoading
              ? const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.2,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(width: AppSpacing.sm),
                    Text(
                      'Giris Yapiliyor...',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                  ],
                )
              : const Text(
                  'Giris Yap',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                    letterSpacing: 0.3,
                  ),
                ),
        ),
      ),
    );
  }

  Widget _buildGoogleButton(ThemeData theme) {
    final isDark = theme.brightness == Brightness.dark;

    return SizedBox(
      height: 54,
      child: OutlinedButton(
        onPressed: _isGoogleLoading ? null : _signInWithGoogle,
        style: OutlinedButton.styleFrom(
          backgroundColor: isDark
              ? AppColors.surfaceVariantDark.withOpacity(0.5)
              : Colors.white,
          side: BorderSide(
            color: isDark
                ? AppColors.outlineDark.withOpacity(0.5)
                : AppColors.outline.withOpacity(0.8),
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.lg),
          ),
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          elevation: 0,
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
                    width: 26,
                    height: 26,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(6),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.08),
                          blurRadius: 4,
                          offset: const Offset(0, 1),
                        ),
                      ],
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
                          ).createShader(
                              const Rect.fromLTWH(0, 0, 26, 26)),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Text(
                      'Google ile devam et',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  const SizedBox(width: 26 + AppSpacing.md),
                ],
              ),
      ),
    );
  }
}

// Animated gradient background widget
class _AnimatedGradientBackground extends StatelessWidget {
  final AnimationController controller;
  final bool isDark;

  const _AnimatedGradientBackground({
    required this.controller,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final value = controller.value;
        final angle = value * 2 * math.pi;

        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment(
                math.cos(angle) * 0.5,
                math.sin(angle) * 0.5,
              ),
              end: Alignment(
                math.cos(angle + math.pi) * 0.5,
                math.sin(angle + math.pi) * 0.5,
              ),
              colors: isDark
                  ? [
                      AppColors.backgroundDark,
                      const Color(0xFF1E1814),
                      const Color(0xFF241C16),
                      AppColors.backgroundDark,
                    ]
                  : [
                      AppColors.background,
                      const Color(0xFFFFF8F2),
                      const Color(0xFFFDF2E9),
                      AppColors.background,
                    ],
            ),
          ),
        );
      },
    );
  }
}
