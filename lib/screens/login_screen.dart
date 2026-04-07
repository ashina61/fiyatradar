import 'package:flutter/material.dart';
import 'main_screen.dart';
import '../theme.dart';
import '../widgets/design.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();

  bool _rememberMe = false;
  bool _obscurePassword = true;
  bool _isLoading = false;
  bool _isNavigating = false;
  String? _errorMessage;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _onLogin() async {
    // Guard: prevent double submission
    if (_isLoading || _isNavigating) return;
    setState(() => _errorMessage = null);

    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    // Simulate auth latency (anonymous auth already done in AppState.init)
    await Future.delayed(const Duration(milliseconds: 700));

    if (!mounted) return;

    setState(() {
      _isLoading = false;
      _isNavigating = true;
    });

    // Single, safe navigation – replace entire stack
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const MainScreen()),
      (_) => false,
    );
  }

  Future<void> _onGuestContinue() async {
    if (_isNavigating) return;
    setState(() => _isNavigating = true);

    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const MainScreen()),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CoffeeColors.cream,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(28, 0, 28, 32),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                    minHeight: constraints.maxHeight),
                child: IntrinsicHeight(
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const SizedBox(height: 48),

                        // ── Branding ─────────────────────────────────
                        Center(
                          child: Column(
                            children: [
                              Container(
                                width: 72,
                                height: 72,
                                decoration: BoxDecoration(
                                  color: CoffeeColors.espresso,
                                  borderRadius: BorderRadius.circular(22),
                                  boxShadow: [
                                    BoxShadow(
                                      color: CoffeeColors.espresso
                                          .withOpacity(0.3),
                                      blurRadius: 24,
                                      offset: const Offset(0, 10),
                                    ),
                                  ],
                                ),
                                alignment: Alignment.center,
                                child: const Text('☕',
                                    style: TextStyle(fontSize: 34)),
                              ),
                              const SizedBox(height: 16),
                              const Text(
                                'FiyatRadar',
                                style: TextStyle(
                                  color: CoffeeColors.espresso,
                                  fontSize: 26,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: -0.6,
                                ),
                              ),
                              const SizedBox(height: 6),
                              const Text(
                                'Topluluk gücüyle fiyat avantajı',
                                style: TextStyle(
                                  color: CoffeeColors.cocoa,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 40),

                        // ── Form card ─────────────────────────────────
                        Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(color: CoffeeColors.crema),
                            boxShadow: FR.softShadow,
                          ),
                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.stretch,
                            children: [
                              const Text(
                                'Hesabına Giriş Yap',
                                style: TextStyle(
                                  color: CoffeeColors.espresso,
                                  fontSize: 19,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: -0.4,
                                ),
                              ),
                              const SizedBox(height: 6),
                              const Text(
                                'Devam etmek için bilgilerini gir',
                                style: TextStyle(
                                    color: CoffeeColors.cocoa,
                                    fontSize: 13),
                              ),
                              const SizedBox(height: 22),

                              // Email
                              TextFormField(
                                controller: _emailCtrl,
                                keyboardType:
                                    TextInputType.emailAddress,
                                textInputAction: TextInputAction.next,
                                autocorrect: false,
                                decoration: const InputDecoration(
                                  hintText: 'E-posta adresin',
                                  prefixIcon: Icon(Icons.mail_outline,
                                      color: CoffeeColors.cocoa,
                                      size: 20),
                                ),
                                validator: (v) {
                                  if (v == null || v.trim().isEmpty) {
                                    return 'E-posta zorunlu';
                                  }
                                  if (!v.contains('@') ||
                                      !v.contains('.')) {
                                    return 'Geçerli e-posta gir';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 12),

                              // Password
                              TextFormField(
                                controller: _passwordCtrl,
                                obscureText: _obscurePassword,
                                textInputAction: TextInputAction.done,
                                onFieldSubmitted: (_) => _onLogin(),
                                decoration: InputDecoration(
                                  hintText: 'Şifren',
                                  prefixIcon: const Icon(
                                      Icons.lock_outline,
                                      color: CoffeeColors.cocoa,
                                      size: 20),
                                  suffixIcon: IconButton(
                                    onPressed: () => setState(() =>
                                        _obscurePassword =
                                            !_obscurePassword),
                                    icon: Icon(
                                      _obscurePassword
                                          ? Icons.visibility_off_outlined
                                          : Icons.visibility_outlined,
                                      color: CoffeeColors.cocoa,
                                      size: 20,
                                    ),
                                  ),
                                ),
                                validator: (v) {
                                  if (v == null || v.isEmpty) {
                                    return 'Şifre zorunlu';
                                  }
                                  if (v.length < 6) {
                                    return 'En az 6 karakter olmalı';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 12),

                              // Remember me + Forgot password
                              Row(
                                children: [
                                  GestureDetector(
                                    onTap: () => setState(() =>
                                        _rememberMe = !_rememberMe),
                                    child: Row(
                                      children: [
                                        AnimatedContainer(
                                          duration: const Duration(
                                              milliseconds: 180),
                                          width: 20,
                                          height: 20,
                                          decoration: BoxDecoration(
                                            color: _rememberMe
                                                ? CoffeeColors.espresso
                                                : Colors.white,
                                            borderRadius:
                                                BorderRadius.circular(5),
                                            border: Border.all(
                                              color: _rememberMe
                                                  ? CoffeeColors.espresso
                                                  : CoffeeColors.crema,
                                            ),
                                          ),
                                          child: _rememberMe
                                              ? const Icon(Icons.check,
                                                  color: CoffeeColors.cream,
                                                  size: 14)
                                              : null,
                                        ),
                                        const SizedBox(width: 8),
                                        const Text(
                                          'Beni hatırla',
                                          style: TextStyle(
                                            color: CoffeeColors.darkRoast,
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const Spacer(),
                                  GestureDetector(
                                    onTap: () {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                              'Şifre sıfırlama maili gönderildi'),
                                          backgroundColor:
                                              CoffeeColors.darkRoast,
                                          behavior:
                                              SnackBarBehavior.floating,
                                        ),
                                      );
                                    },
                                    child: const Text(
                                      'Şifremi unuttum',
                                      style: TextStyle(
                                        color: CoffeeColors.caramel,
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                ],
                              ),

                              // Error message
                              if (_errorMessage != null) ...[
                                const SizedBox(height: 12),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 10),
                                  decoration: BoxDecoration(
                                    color: CoffeeColors.danger
                                        .withOpacity(0.08),
                                    borderRadius:
                                        BorderRadius.circular(10),
                                    border: Border.all(
                                        color: CoffeeColors.danger
                                            .withOpacity(0.3)),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.error_outline,
                                          color: CoffeeColors.danger,
                                          size: 16),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          _errorMessage!,
                                          style: const TextStyle(
                                            color: CoffeeColors.danger,
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],

                              const SizedBox(height: 20),

                              // Login button
                              ElevatedButton(
                                onPressed:
                                    _isLoading ? null : _onLogin,
                                style: ElevatedButton.styleFrom(
                                  minimumSize:
                                      const Size.fromHeight(54),
                                  shape: RoundedRectangleBorder(
                                    borderRadius:
                                        BorderRadius.circular(16),
                                  ),
                                ),
                                child: _isLoading
                                    ? const SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2.5,
                                          color: CoffeeColors.cream,
                                        ),
                                      )
                                    : const Text('Giriş Yap'),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),

                        // ── Register link ─────────────────────────────
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text(
                              'Hesabın yok mu?',
                              style: TextStyle(
                                  color: CoffeeColors.cocoa,
                                  fontSize: 13),
                            ),
                            const SizedBox(width: 6),
                            GestureDetector(
                              onTap: () {
                                // Show coming soon snackbar
                                ScaffoldMessenger.of(context)
                                    .showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                        'Kayıt yakında aktif olacak'),
                                    backgroundColor:
                                        CoffeeColors.darkRoast,
                                    behavior: SnackBarBehavior.floating,
                                  ),
                                );
                              },
                              child: const Text(
                                'Kayıt Ol',
                                style: TextStyle(
                                  color: CoffeeColors.caramel,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ],
                        ),

                        const Spacer(),
                        const SizedBox(height: 16),

                        // ── Guest mode ────────────────────────────────
                        GestureDetector(
                          onTap: _onGuestContinue,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                vertical: 14),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border:
                                  Border.all(color: CoffeeColors.crema),
                            ),
                            alignment: Alignment.center,
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.person_outline,
                                    color: CoffeeColors.cocoa, size: 18),
                                SizedBox(width: 8),
                                Text(
                                  'Misafir olarak devam et',
                                  style: TextStyle(
                                    color: CoffeeColors.darkRoast,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 14,
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
              ),
            );
          },
        ),
      ),
    );
  }
}
