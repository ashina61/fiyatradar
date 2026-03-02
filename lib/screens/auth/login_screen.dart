import 'dart:ui';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../providers/auth_provider.dart';
import '../../providers/firebase_init_provider.dart';
import '../../utils/theme.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _emailFocusNode = FocusNode();
  final _passwordFocusNode = FocusNode();

  bool _isLoading = false;
  bool _isGoogleLoading = false;
  bool _obscurePassword = true;
  bool _rememberMe = false;

  static const Color _bgColor = Color(0xFFF8F5F2);
  static const Color _primaryBrown = Color(0xFF6B4226);
  static const Color _darkBrown = Color(0xFF4A2E1B);
  static const Color _softBrown = Color(0xFF8C6A53);
  static const Color _placeholder = Color(0xFFB59A86);

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _emailFocusNode.dispose();
    _passwordFocusNode.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    if (!ref.read(firebaseInitializedProvider)) {
      _showErrorSnackBar(
        'Firebase bağlantısı kurulamadı. Lütfen internet bağlantınızı kontrol edin.',
      );
      setState(() => _isLoading = false);
      return;
    }

    try {
      await ref.read(authServiceProvider).signInWithEmailAndPassword(
            email: _emailController.text.trim(),
            password: _passwordController.text,
          );
      if (!mounted) return;
      context.go('/main');
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      _showErrorSnackBar(ref.read(authServiceProvider).getErrorMessage(e));
    } catch (e) {
      if (!mounted) return;
      _showErrorSnackBar('Giriş yapılamadı: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _signInWithGoogle() async {
    if (!ref.read(firebaseInitializedProvider)) {
      _showErrorSnackBar(
        'Firebase bağlantısı kurulamadı. Lütfen internet bağlantınızı kontrol edin.',
      );
      return;
    }

    setState(() => _isGoogleLoading = true);

    try {
      final user = await ref.read(authServiceProvider).signInWithGoogle();

      if (user != null && mounted) {
        context.go('/main');
      } else if (mounted) {
        setState(() => _isGoogleLoading = false);
      }
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      _showErrorSnackBar(ref.read(authServiceProvider).getErrorMessage(e));
      setState(() => _isGoogleLoading = false);
    } catch (e) {
      if (!mounted) return;
      _showErrorSnackBar('Google ile giriş yapılamadı.');
      setState(() => _isGoogleLoading = false);
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: _primaryBrown,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        margin: const EdgeInsets.all(AppSpacing.md),
      ),
    );
  }

  void _showForgotPasswordDialog() {
    final emailController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Text(
          'Şifremi Unuttum',
          style: GoogleFonts.outfit(
            color: _darkBrown,
            fontWeight: FontWeight.w600,
          ),
        ),
        content: TextField(
          controller: emailController,
          keyboardType: TextInputType.emailAddress,
          decoration: InputDecoration(
            hintText: 'E-posta adresiniz',
            hintStyle: GoogleFonts.outfit(color: _placeholder),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('İptal', style: GoogleFonts.outfit(color: _softBrown)),
          ),
          TextButton(
            onPressed: () async {
              if (emailController.text.isEmpty) return;
              try {
                await ref
                    .read(authServiceProvider)
                    .resetPassword(emailController.text.trim());
                if (!mounted) return;
                Navigator.pop(ctx);
              } catch (_) {
                Navigator.pop(ctx);
                _showErrorSnackBar('E-posta gönderilemedi.');
              }
            },
            child: Text(
              'Gönder',
              style: GoogleFonts.outfit(
                color: _primaryBrown,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: DefaultTextStyle(
        style: GoogleFonts.outfit(),
        child: Stack(
          children: [
            Container(color: _bgColor),
            Positioned(
              top: -50,
              left: -100,
              child: ImageFiltered(
                imageFilter: ImageFilter.blur(sigmaX: 60, sigmaY: 60),
                child: Container(
                  width: 300,
                  height: 300,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Color(0x26A66632),
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: 50,
              right: -50,
              child: ImageFiltered(
                imageFilter: ImageFilter.blur(sigmaX: 60, sigmaY: 60),
                child: Container(
                  width: 250,
                  height: 250,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Color(0x1A6B4226),
                  ),
                ),
              ),
            ),
            SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 400),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(32),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                        child: Container(
                          padding: const EdgeInsets.fromLTRB(30, 40, 30, 30),
                          decoration: BoxDecoration(
                            color: const Color(0x99FFFFFF),
                            borderRadius: BorderRadius.circular(32),
                            border: Border.all(color: const Color(0xCCFFFFFF)),
                            boxShadow: const [
                              BoxShadow(
                                color: Color(0x0D6B4226),
                                blurRadius: 40,
                                offset: Offset(0, 20),
                              ),
                            ],
                          ),
                          child: _buildCardContent(),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCardContent() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildBrandHeader(),
          const SizedBox(height: 35),
          _PremiumInputGroup(
            controller: _emailController,
            focusNode: _emailFocusNode,
            hintText: 'E-posta adresin',
            icon: Icons.alternate_email,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Lütfen e-posta adresinizi girin';
              }
              if (!value.contains('@')) return 'Geçerli bir e-posta girin';
              return null;
            },
          ),
          const SizedBox(height: 20),
          _PremiumInputGroup(
            controller: _passwordController,
            focusNode: _passwordFocusNode,
            hintText: 'Şifren',
            icon: Icons.key,
            obscureText: _obscurePassword,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _isLoading ? null : _login(),
            suffix: IconButton(
              onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
              icon: Icon(
                _obscurePassword ? Icons.visibility : Icons.visibility_off,
                color: _placeholder,
              ),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Lütfen şifrenizi girin';
              }
              if (value.length < 6) return 'Şifre en az 6 karakter olmalıdır';
              return null;
            },
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              InkWell(
                onTap: () => setState(() => _rememberMe = !_rememberMe),
                borderRadius: BorderRadius.circular(10),
                child: Row(
                  children: [
                    SizedBox(
                      width: 20,
                      height: 20,
                      child: Checkbox(
                        value: _rememberMe,
                        onChanged: (value) => setState(() => _rememberMe = value ?? false),
                        activeColor: _primaryBrown,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                        side: const BorderSide(color: _softBrown),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Beni hatırla',
                      style: GoogleFonts.outfit(color: _softBrown, fontSize: 13),
                    ),
                  ],
                ),
              ),
              TextButton(
                onPressed: _showForgotPasswordDialog,
                style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: Size.zero),
                child: Text(
                  'Şifremi unuttum',
                  style: GoogleFonts.outfit(
                    color: _primaryBrown,
                    fontWeight: FontWeight.w500,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 54,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _login,
              style: ElevatedButton.styleFrom(
                backgroundColor: _primaryBrown,
                foregroundColor: Colors.white,
                elevation: 0,
                shadowColor: const Color(0x406B4226),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : Text(
                      'Giriş Yap',
                      style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w600),
                    ),
            ),
          ),
          const SizedBox(height: 30),
          _buildElegantDivider(),
          const SizedBox(height: 20),
          SizedBox(
            height: 54,
            child: OutlinedButton(
              onPressed: _isGoogleLoading ? null : _signInWithGoogle,
              style: OutlinedButton.styleFrom(
                backgroundColor: const Color(0xE6FFFFFF),
                side: const BorderSide(color: Color(0x26A66632)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: _isGoogleLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: _primaryBrown),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 22,
                          height: 22,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            'G',
                            style: GoogleFonts.outfit(
                              color: const Color(0xFF4285F4),
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Google ile Giriş Yap',
                          style: GoogleFonts.outfit(
                            color: _darkBrown,
                            fontWeight: FontWeight.w500,
                            fontSize: 15,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
          const SizedBox(height: 24),
          Center(
            child: RichText(
              text: TextSpan(
                style: GoogleFonts.outfit(color: _softBrown, fontSize: 14),
                children: [
                  const TextSpan(text: 'FiyatRadar\'da yeni misin? '),
                  WidgetSpan(
                    alignment: PlaceholderAlignment.middle,
                    child: GestureDetector(
                      onTap: () => context.go('/register'),
                      child: Text(
                        'Hemen Katıl',
                        style: GoogleFonts.outfit(
                          color: _primaryBrown,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBrandHeader() {
    return Column(
      children: [
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF8C5938), Color(0xFF6B4226)],
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: const [
              BoxShadow(
                color: Color(0x336B4226),
                blurRadius: 20,
                offset: Offset(0, 10),
              ),
            ],
          ),
          child: const Icon(Icons.radar, color: Colors.white, size: 32),
        ),
        const SizedBox(height: 16),
        Text(
          'FiyatRadar',
          style: GoogleFonts.outfit(
            fontSize: 28,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.5,
            color: _darkBrown,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Akıllı alışverişin premium yolu.',
          style: GoogleFonts.outfit(
            fontSize: 14,
            fontWeight: FontWeight.w300,
            color: _softBrown,
          ),
        ),
      ],
    );
  }

  Widget _buildElegantDivider() {
    return Stack(
      alignment: Alignment.center,
      children: [
        Container(
          height: 1,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.transparent,
                Color(0x33A66632),
                Colors.transparent,
              ],
            ),
          ),
        ),
        Container(
          color: const Color(0x99FFFFFF),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'veya şununla devam et',
            style: GoogleFonts.outfit(
              color: const Color(0xFFA38671),
              fontSize: 12,
            ),
          ),
        ),
      ],
    );
  }
}

class _PremiumInputGroup extends StatefulWidget {
  const _PremiumInputGroup({
    required this.controller,
    required this.focusNode,
    required this.hintText,
    required this.icon,
    this.keyboardType,
    this.textInputAction,
    this.obscureText = false,
    this.suffix,
    this.validator,
    this.onSubmitted,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final String hintText;
  final IconData icon;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final bool obscureText;
  final Widget? suffix;
  final String? Function(String?)? validator;
  final void Function(String)? onSubmitted;

  @override
  State<_PremiumInputGroup> createState() => _PremiumInputGroupState();
}

class _PremiumInputGroupState extends State<_PremiumInputGroup> {
  bool _hasFocus = false;

  @override
  void initState() {
    super.initState();
    widget.focusNode.addListener(_onFocusChanged);
  }

  @override
  void dispose() {
    widget.focusNode.removeListener(_onFocusChanged);
    super.dispose();
  }

  void _onFocusChanged() {
    if (!mounted) return;
    setState(() => _hasFocus = widget.focusNode.hasFocus);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: _hasFocus ? Colors.white : const Color(0xCCFFFFFF),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _hasFocus ? const Color(0xFF6B4226) : const Color(0x1AA66632),
        ),
        boxShadow: _hasFocus
            ? const [
                BoxShadow(
                  color: Color(0x0F6B4226),
                  blurRadius: 16,
                  offset: Offset(0, 8),
                ),
              ]
            : null,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        children: [
          Icon(widget.icon, color: const Color(0xFFB59A86), size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: TextFormField(
              controller: widget.controller,
              focusNode: widget.focusNode,
              keyboardType: widget.keyboardType,
              textInputAction: widget.textInputAction,
              obscureText: widget.obscureText,
              onFieldSubmitted: widget.onSubmitted,
              validator: widget.validator,
              style: GoogleFonts.outfit(
                fontSize: 15,
                color: const Color(0xFF4A2E1B),
              ),
              decoration: InputDecoration(
                hintText: widget.hintText,
                hintStyle: GoogleFonts.outfit(
                  color: const Color(0xFFB59A86),
                  fontWeight: FontWeight.w300,
                ),
                border: InputBorder.none,
                errorBorder: InputBorder.none,
                focusedErrorBorder: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
          if (widget.suffix != null) widget.suffix!,
        ],
      ),
    );
  }
}
