import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../services/firebase_service.dart';
import '../state/app_state.dart';
import '../theme.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();

  bool _registerMode = false;
  bool _obscure = true;
  bool _submitting = false;
  String? _error;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_submitting) return;
    setState(() => _error = null);
    if (!_formKey.currentState!.validate()) return;

    final state = AppStateScope.of(context);
    final svc = FirebaseService.instance;

    setState(() => _submitting = true);
    try {
      final email = _emailCtrl.text.trim();
      final password = _passwordCtrl.text.trim();
      if (_registerMode) {
        await svc.registerWithEmail(
          email: email,
          password: password,
          displayName: _nameCtrl.text.trim(),
        );
      } else {
        await svc.signInWithEmail(email: email, password: password);
      }
      await state.refreshFromAuthSession();
      if (!mounted) return;
      Navigator.of(context).popUntil((route) => route.isFirst);
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      setState(() => _error = _mapAuthError(e));
    } catch (_) {
      if (!mounted) return;
      setState(() => _error = 'Giriş sırasında beklenmeyen bir hata oluştu.');
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Future<void> _forgotPassword() async {
    final email = _emailCtrl.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      setState(() => _error = 'Şifre sıfırlama için geçerli e-posta gir.');
      return;
    }
    try {
      await FirebaseService.instance.sendPasswordReset(email);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Şifre sıfırlama e-postası gönderildi.'),
          backgroundColor: CoffeeColors.darkRoast,
        ),
      );
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      setState(() => _error = _mapAuthError(e));
    }
  }

  Future<void> _continueAsGuest() async {
    if (_submitting) return;
    final state = AppStateScope.of(context);
    setState(() => _submitting = true);
    try {
      await FirebaseService.instance.ensureSignedIn();
      await state.refreshFromAuthSession();
      if (!mounted) return;
      Navigator.of(context).popUntil((route) => route.isFirst);
    } catch (_) {
      if (!mounted) return;
      setState(() => _error = 'Misafir oturumu başlatılamadı.');
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  String _mapAuthError(FirebaseAuthException e) {
    switch (e.code) {
      case 'invalid-email':
        return 'E-posta formatı geçersiz.';
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
        return 'E-posta veya şifre hatalı.';
      case 'email-already-in-use':
        return 'Bu e-posta zaten kayıtlı.';
      case 'weak-password':
        return 'Şifre çok zayıf. En az 6 karakter kullan.';
      case 'too-many-requests':
        return 'Çok fazla deneme yapıldı. Lütfen biraz bekleyin.';
      default:
        return e.message ?? 'Kimlik doğrulama hatası.';
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = _registerMode ? 'Hesap Oluştur' : 'Giriş Yap';
    final subtitle = _registerMode
        ? 'Topluluğa katıl, fiyat katkılarına başla.'
        : 'FiyatRadar hesabınla güvenli şekilde devam et.';

    return Scaffold(
      backgroundColor: CoffeeColors.cream,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Container(
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: CoffeeColors.crema),
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text(
                        'FiyatRadar',
                        style: TextStyle(
                          color: CoffeeColors.espresso,
                          fontWeight: FontWeight.w800,
                          fontSize: 26,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        title,
                        style: const TextStyle(
                          color: CoffeeColors.darkRoast,
                          fontWeight: FontWeight.w700,
                          fontSize: 18,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(subtitle, style: const TextStyle(color: CoffeeColors.cocoa, fontSize: 13)),
                      const SizedBox(height: 16),
                      if (_registerMode) ...[
                        TextFormField(
                          controller: _nameCtrl,
                          textInputAction: TextInputAction.next,
                          decoration: const InputDecoration(
                            hintText: 'Ad Soyad',
                            prefixIcon: Icon(Icons.person_outline, size: 20, color: CoffeeColors.cocoa),
                          ),
                          validator: (v) {
                            if (!_registerMode) return null;
                            if (v == null || v.trim().length < 2) return 'En az 2 karakter gir.';
                            return null;
                          },
                        ),
                        const SizedBox(height: 10),
                      ],
                      TextFormField(
                        controller: _emailCtrl,
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.next,
                        decoration: const InputDecoration(
                          hintText: 'E-posta',
                          prefixIcon: Icon(Icons.mail_outline, size: 20, color: CoffeeColors.cocoa),
                        ),
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) return 'E-posta zorunlu.';
                          if (!v.contains('@') || !v.contains('.')) return 'Geçerli e-posta gir.';
                          return null;
                        },
                      ),
                      const SizedBox(height: 10),
                      TextFormField(
                        controller: _passwordCtrl,
                        obscureText: _obscure,
                        textInputAction: TextInputAction.done,
                        onFieldSubmitted: (_) => _submit(),
                        decoration: InputDecoration(
                          hintText: 'Şifre',
                          prefixIcon: const Icon(Icons.lock_outline, size: 20, color: CoffeeColors.cocoa),
                          suffixIcon: IconButton(
                            onPressed: () => setState(() => _obscure = !_obscure),
                            icon: Icon(
                              _obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                              size: 20,
                              color: CoffeeColors.cocoa,
                            ),
                          ),
                        ),
                        validator: (v) {
                          if (v == null || v.isEmpty) return 'Şifre zorunlu.';
                          if (v.length < 6) return 'En az 6 karakter olmalı.';
                          return null;
                        },
                      ),
                      if (!_registerMode)
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: _submitting ? null : _forgotPassword,
                            child: const Text('Şifremi unuttum'),
                          ),
                        ),
                      if (_error != null)
                        Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                          decoration: BoxDecoration(
                            color: CoffeeColors.danger.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: CoffeeColors.danger.withOpacity(0.25)),
                          ),
                          child: Text(
                            _error!,
                            style: const TextStyle(color: CoffeeColors.danger, fontSize: 12, fontWeight: FontWeight.w600),
                          ),
                        ),
                      ElevatedButton(
                        onPressed: _submitting ? null : _submit,
                        style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(52)),
                        child: _submitting
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(strokeWidth: 2, color: CoffeeColors.cream),
                              )
                            : Text(_registerMode ? 'Hesap Oluştur' : 'Giriş Yap'),
                      ),
                      const SizedBox(height: 8),
                      OutlinedButton(
                        onPressed: _submitting ? null : _continueAsGuest,
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size.fromHeight(48),
                          side: const BorderSide(color: CoffeeColors.crema),
                          foregroundColor: CoffeeColors.darkRoast,
                        ),
                        child: const Text('Misafir olarak devam et'),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            _registerMode ? 'Zaten hesabın var mı?' : 'Hesabın yok mu?',
                            style: const TextStyle(color: CoffeeColors.cocoa, fontSize: 12),
                          ),
                          TextButton(
                            onPressed: _submitting
                                ? null
                                : () => setState(() {
                                      _registerMode = !_registerMode;
                                      _error = null;
                                    }),
                            child: Text(_registerMode ? 'Giriş Yap' : 'Kayıt Ol'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
