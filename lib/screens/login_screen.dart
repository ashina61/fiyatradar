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
  bool _showRegister = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CoffeeColors.cream,
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 280),
        child: _showRegister
            ? _RegisterView(onBack: () => setState(() => _showRegister = false))
            : _LoginView(onRegister: () => setState(() => _showRegister = true)),
      ),
    );
  }
}

// ─── Login view ───────────────────────────────────────────────────────────────

class _LoginView extends StatefulWidget {
  const _LoginView({required this.onRegister});
  final VoidCallback onRegister;

  @override
  State<_LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<_LoginView> {
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
    if (_isLoading || _isNavigating) return;
    setState(() => _errorMessage = null);
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    await Future.delayed(const Duration(milliseconds: 700));
    if (!mounted) return;
    setState(() {
      _isLoading = false;
      _isNavigating = true;
    });
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
    return SafeArea(
      child: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(28, 0, 28, 32),
            child: ConstrainedBox(
              constraints:
                  BoxConstraints(minHeight: constraints.maxHeight),
              child: IntrinsicHeight(
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: 52),

                      // ── Branding ──────────────────────────────────
                      Center(
                        child: Column(
                          children: [
                            Container(
                              width: 76,
                              height: 76,
                              decoration: BoxDecoration(
                                color: CoffeeColors.espresso,
                                borderRadius: BorderRadius.circular(24),
                                boxShadow: [
                                  BoxShadow(
                                    color: CoffeeColors.espresso
                                        .withOpacity(0.30),
                                    blurRadius: 28,
                                    offset: const Offset(0, 12),
                                  ),
                                ],
                              ),
                              alignment: Alignment.center,
                              child: const Text('☕',
                                  style: TextStyle(fontSize: 34)),
                            ),
                            const SizedBox(height: 14),
                            const Text(
                              'FiyatRadar',
                              style: TextStyle(
                                color: CoffeeColors.espresso,
                                fontSize: 28,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.7,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                LiveDot(),
                                const SizedBox(width: 5),
                                const Text(
                                  'Topluluk gücüyle fiyat avantajı',
                                  style: TextStyle(
                                    color: CoffeeColors.cocoa,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 36),

                      // ── Form card ──────────────────────────────────
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(color: CoffeeColors.crema),
                          boxShadow: FR.softShadow,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
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
                            const SizedBox(height: 4),
                            const Text(
                              'Devam etmek için bilgilerini gir',
                              style: TextStyle(
                                  color: CoffeeColors.cocoa, fontSize: 13),
                            ),
                            const SizedBox(height: 22),

                            // Email
                            TextFormField(
                              controller: _emailCtrl,
                              keyboardType: TextInputType.emailAddress,
                              textInputAction: TextInputAction.next,
                              autocorrect: false,
                              decoration: const InputDecoration(
                                hintText: 'E-posta adresin',
                                prefixIcon: Icon(Icons.mail_outline,
                                    color: CoffeeColors.cocoa, size: 20),
                              ),
                              validator: (v) {
                                if (v == null || v.trim().isEmpty) {
                                  return 'E-posta zorunlu';
                                }
                                if (!v.contains('@') || !v.contains('.')) {
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
                                prefixIcon: const Icon(Icons.lock_outline,
                                    color: CoffeeColors.cocoa, size: 20),
                                suffixIcon: IconButton(
                                  onPressed: () => setState(() =>
                                      _obscurePassword = !_obscurePassword),
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
                            const SizedBox(height: 14),

                            // Remember me + Forgot password
                            Row(
                              children: [
                                GestureDetector(
                                  onTap: () => setState(
                                      () => _rememberMe = !_rememberMe),
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
                              onPressed: _isLoading ? null : _onLogin,
                              style: ElevatedButton.styleFrom(
                                minimumSize: const Size.fromHeight(54),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
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
                      const SizedBox(height: 16),

                      // ── Register link ──────────────────────────────
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text(
                            'Hesabın yok mu?',
                            style: TextStyle(
                                color: CoffeeColors.cocoa, fontSize: 13),
                          ),
                          const SizedBox(width: 6),
                          GestureDetector(
                            onTap: widget.onRegister,
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
                          padding: const EdgeInsets.symmetric(vertical: 14),
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
    );
  }
}

// ─── Register view ────────────────────────────────────────────────────────────

class _RegisterView extends StatefulWidget {
  const _RegisterView({required this.onBack});
  final VoidCallback onBack;

  @override
  State<_RegisterView> createState() => _RegisterViewState();
}

class _RegisterViewState extends State<_RegisterView> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _onRegister() async {
    if (_isLoading) return;
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    await Future.delayed(const Duration(milliseconds: 900));
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const MainScreen()),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(28, 0, 28, 32),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 24),

              // Back
              GestureDetector(
                onTap: widget.onBack,
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: CoffeeColors.crema),
                      ),
                      child: const Icon(Icons.arrow_back,
                          color: CoffeeColors.darkRoast, size: 18),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'Giriş Yap',
                      style: TextStyle(
                        color: CoffeeColors.caramel,
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // Header
              const Text(
                'Hesap Oluştur',
                style: TextStyle(
                  color: CoffeeColors.espresso,
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.7,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Topluluga katıl, fiyat avantajından yararlan',
                style: TextStyle(color: CoffeeColors.cocoa, fontSize: 13),
              ),
              const SizedBox(height: 28),

              // Form card
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: CoffeeColors.crema),
                  boxShadow: FR.softShadow,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextFormField(
                      controller: _nameCtrl,
                      textInputAction: TextInputAction.next,
                      textCapitalization: TextCapitalization.words,
                      decoration: const InputDecoration(
                        hintText: 'Adın',
                        prefixIcon: Icon(Icons.person_outline,
                            color: CoffeeColors.cocoa, size: 20),
                      ),
                      validator: (v) {
                        if (v == null || v.trim().length < 2) {
                          return 'En az 2 karakter gir';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _emailCtrl,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      autocorrect: false,
                      decoration: const InputDecoration(
                        hintText: 'E-posta adresin',
                        prefixIcon: Icon(Icons.mail_outline,
                            color: CoffeeColors.cocoa, size: 20),
                      ),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) {
                          return 'E-posta zorunlu';
                        }
                        if (!v.contains('@') || !v.contains('.')) {
                          return 'Geçerli e-posta gir';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _passwordCtrl,
                      obscureText: _obscurePassword,
                      textInputAction: TextInputAction.done,
                      onFieldSubmitted: (_) => _onRegister(),
                      decoration: InputDecoration(
                        hintText: 'Şifre oluştur (en az 6 karakter)',
                        prefixIcon: const Icon(Icons.lock_outline,
                            color: CoffeeColors.cocoa, size: 20),
                        suffixIcon: IconButton(
                          onPressed: () => setState(() =>
                              _obscurePassword = !_obscurePassword),
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
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: _isLoading ? null : _onRegister,
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size.fromHeight(54),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
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
                          : const Text('Hesap Oluştur'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Privacy note
              const Center(
                child: Text(
                  'Kaydolarak Kullanım Koşulları\'nı kabul etmiş olursun.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: CoffeeColors.cocoa,
                    fontSize: 11,
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
