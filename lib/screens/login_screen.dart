import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../services/firebase_service.dart';
import '../state/app_state.dart';
import '../ui/components.dart';
import '../ui/tokens.dart';

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
      User? signedUser;
      if (_registerMode) {
        final cred = await svc.registerWithEmail(
          email: email,
          password: password,
          displayName: _nameCtrl.text.trim(),
        );
        signedUser = cred.user;
      } else {
        final cred = await svc.signInWithEmail(email: email, password: password);
        signedUser = cred.user;
      }
      final current = signedUser ?? svc.auth.currentUser;
      if (current == null || current.isAnonymous) {
        throw FirebaseAuthException(
          code: 'session-invalid',
          message: 'Oturum doğrulanamadı.',
        );
      }
      state.syncUserFromAuthSession();
      state.setGuestAcknowledged(false);
      unawaited(
        state
            .refreshFromAuthSession(preserveGuestAcknowledged: false)
            .catchError((_) {}),
      );
      // No Navigator.pop needed: the root _AuthGate listens to AppState and
      // swaps LoginScreen → MainScreen as soon as `user` becomes non-anon.
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
        const SnackBar(content: Text('Şifre sıfırlama e-postası gönderildi.')),
      );
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      setState(() => _error = _mapAuthError(e));
    }
  }

  Future<void> _continueAsGuest() async {
    if (_submitting) return;
    setState(() => _error = null);
    final state = AppStateScope.of(context);
    setState(() => _submitting = true);
    try {
      final guest = await FirebaseService.instance.ensureSignedIn();
      if (!guest.isAnonymous) {
        throw FirebaseAuthException(
          code: 'guest-auth-failed',
          message: 'Misafir oturumu başlatılamadı.',
        );
      }
      state.syncUserFromAuthSession();
      state.setGuestAcknowledged(true);
      unawaited(
        state
            .refreshFromAuthSession(preserveGuestAcknowledged: true)
            .catchError((_) {}),
      );
      // Auth gate handles the route swap.
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      setState(() => _error = _mapAuthError(e));
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
        return 'Çok fazla deneme yapıldı. Lütfen biraz bekle.';
      default:
        return e.message ?? 'Kimlik doğrulama hatası.';
    }
  }

  @override
  Widget build(BuildContext context) {
    final overline = _registerMode ? 'KAYIT' : 'GİRİŞ';
    final title = _registerMode ? 'Topluluğa katıl.' : 'Tekrar hoş geldin.';
    final subtitle = _registerMode
        ? 'Hesap aç, ilk fiyatını paylaş, +25 PT kazan.'
        : 'FiyatRadar hesabınla kaldığın yerden devam et.';

    return Scaffold(
      backgroundColor: FR.bg,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(22, 24, 22, 24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(colors: [FR.goldHi, FR.goldDeep]),
                          borderRadius: FRRad.all(12),
                        ),
                        alignment: Alignment.center,
                        child: Text('FR', style: frDisplay(15, FontWeight.w800, color: FR.onGold)),
                      ),
                      const SizedBox(width: 10),
                      Text('FiyatRadar', style: frText(16, FontWeight.w800)),
                    ],
                  ),
                  const SizedBox(height: 28),
                  Text(overline, style: frOverline()),
                  const SizedBox(height: 6),
                  Text(title, style: frDisplay(36, FontWeight.w700)),
                  const SizedBox(height: 6),
                  Text(subtitle, style: frText(13, FontWeight.w500, color: FR.ink3, height: 1.5)),
                  const SizedBox(height: 22),
                  Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (_registerMode) ...[
                          _field(
                            controller: _nameCtrl,
                            hint: 'Ad Soyad',
                            icon: Icons.person_outline_rounded,
                            validator: (v) {
                              if (!_registerMode) return null;
                              if (v == null || v.trim().length < 2) return 'En az 2 karakter gir.';
                              return null;
                            },
                          ),
                          const SizedBox(height: 10),
                        ],
                        _field(
                          controller: _emailCtrl,
                          hint: 'E-posta',
                          icon: Icons.alternate_email_rounded,
                          keyboardType: TextInputType.emailAddress,
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) return 'E-posta zorunlu.';
                            if (!v.contains('@') || !v.contains('.')) return 'Geçerli e-posta gir.';
                            return null;
                          },
                        ),
                        const SizedBox(height: 10),
                        _field(
                          controller: _passwordCtrl,
                          hint: 'Şifre',
                          icon: Icons.lock_outline_rounded,
                          obscure: _obscure,
                          onSubmitted: (_) => _submit(),
                          trailing: IconButton(
                            onPressed: () => setState(() => _obscure = !_obscure),
                            icon: Icon(
                              _obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                              size: 20,
                              color: FR.ink3,
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
                              child: Text('Şifremi unuttum',
                                  style: frText(12, FontWeight.w800, color: FR.goldDeep)),
                            ),
                          ),
                        if (_error != null)
                          Container(
                            margin: const EdgeInsets.only(top: 10, bottom: 6),
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            decoration: BoxDecoration(
                              color: FR.bad.withOpacity(.10),
                              borderRadius: FRRad.all(FRRad.m),
                              border: Border.all(color: FR.bad.withOpacity(.35)),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.error_outline_rounded, color: FR.bad, size: 18),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(_error!,
                                      style: frText(12, FontWeight.w700, color: FR.bad)),
                                ),
                              ],
                            ),
                          ),
                        const SizedBox(height: 14),
                        FRCta(
                          label: _submitting
                              ? 'Bekle…'
                              : (_registerMode ? 'Hesap Oluştur' : 'Giriş Yap'),
                          onTap: _submitting ? null : _submit,
                        ),
                        const SizedBox(height: 10),
                        FRCta(
                          label: 'Misafir olarak devam et',
                          icon: Icons.visibility_outlined,
                          filled: false,
                          onTap: _submitting ? null : _continueAsGuest,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _registerMode ? 'Zaten hesabın var mı?' : 'Hesabın yok mu?',
                        style: frText(12, FontWeight.w600, color: FR.ink3),
                      ),
                      TextButton(
                        onPressed: _submitting
                            ? null
                            : () => setState(() {
                                  _registerMode = !_registerMode;
                                  _error = null;
                                }),
                        child: Text(
                          _registerMode ? 'Giriş Yap' : 'Kayıt Ol',
                          style: frText(12, FontWeight.w800, color: FR.gold),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _field({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    TextInputType? keyboardType,
    bool obscure = false,
    Widget? trailing,
    String? Function(String?)? validator,
    ValueChanged<String>? onSubmitted,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscure,
      keyboardType: keyboardType,
      textInputAction: onSubmitted == null ? TextInputAction.next : TextInputAction.done,
      onFieldSubmitted: onSubmitted,
      validator: validator,
      style: frText(14, FontWeight.w700),
      cursorColor: FR.gold,
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: Icon(icon, size: 19, color: FR.ink3),
        suffixIcon: trailing,
      ),
    );
  }
}
