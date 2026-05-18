import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../services/firebase_service.dart';
import '../state/app_state.dart';
import '../ui/components.dart';
import '../ui/tokens.dart';
import 'main_screen.dart';
import 'verify_email_screen.dart';

/// Versioned consent metadata. Bump [_kConsentVersion] whenever the legal
/// text changes; the user's stored consent record gets the active version
/// so we can ask them again on the next breaking change.
const String _kConsentVersion = '2026.05';
const String _kSozlesmeUrl = 'https://fiyatradar.netlify.app/kullanici-sozlesmesi';
const String _kGizlilikUrl = 'https://fiyatradar.netlify.app/gizlilik-politikasi';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _usernameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _passwordConfirmCtrl = TextEditingController();

  bool _registerMode = false;
  bool _obscure = true;
  bool _submitting = false;
  /// Tek bir kutuyla hem 18+ yaş beyanı, hem KVKK + sözleşme onayı alıyoruz
  /// — `_ConsentRow` metni "18 yaşından büyüğüm; … kabul ediyorum (KVKK)"
  /// şeklinde. Kayıtta `users/{uid}.ageConfirmedAt` ve `users/{uid}.consents`
  /// ayrı alanlar olarak yazılır (Play Console data-safety + audit trail).
  bool _consentAccepted = false;
  String? _error;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _usernameCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _passwordConfirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_submitting) return;
    setState(() => _error = null);
    if (!_formKey.currentState!.validate()) return;

    if (_registerMode && !_consentAccepted) {
      setState(() => _error = 'Devam etmek için kullanıcı sözleşmesini ve '
          'gizlilik politikasını onaylaman gerekiyor.');
      return;
    }
    if (_registerMode &&
        _passwordCtrl.text.trim() != _passwordConfirmCtrl.text.trim()) {
      setState(() => _error = 'Şifreler eşleşmiyor.');
      return;
    }

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
          username: _usernameCtrl.text.trim(),
        );
        signedUser = cred.user;
        // Persist KVKK / consent record with version + timestamp so we have
        // an audit trail and can re-prompt on policy changes.
        final uid = cred.user?.uid;
        if (uid != null && uid.isNotEmpty) {
          await svc.userDoc(uid).set({
            'consents': {
              'termsVersion': _kConsentVersion,
              'privacyVersion': _kConsentVersion,
              'acceptedAt': FieldValue.serverTimestamp(),
            },
            'ageConfirmedAt': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));
        }
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
      await state.refreshFromAuthSession(preserveGuestAcknowledged: false);
      if (!mounted) return;
      // E-posta/şifre kayıtlı kullanıcı doğrulamadan uygulamaya
      // giremesin — Google ile gelen (zaten verified) ya da doğrulanmış
      // kullanıcı normal akışla MainScreen'e iner.
      final currentUser = svc.auth.currentUser;
      final needsVerification = currentUser != null &&
          !currentUser.isAnonymous &&
          !currentUser.emailVerified;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (_) => needsVerification
              ? const VerifyEmailScreen()
              : const MainScreen(),
        ),
        (_) => false,
      );
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

  Future<void> _signInWithGoogle() async {
    if (_submitting) return;
    setState(() => _error = null);
    final state = AppStateScope.of(context);
    final svc = FirebaseService.instance;
    setState(() => _submitting = true);
    try {
      final cred = await svc.signInWithGoogle();
      final current = cred.user ?? svc.auth.currentUser;
      if (current == null || current.isAnonymous) {
        throw FirebaseAuthException(
          code: 'session-invalid',
          message: 'Google oturumu doğrulanamadı.',
        );
      }
      state.syncUserFromAuthSession();
      state.setGuestAcknowledged(false);
      await state.refreshFromAuthSession(preserveGuestAcknowledged: false);
      if (!mounted) return;
      // Google hesapları normalde verified gelir; yine de defansif
      // olarak doğrulama gerekiyorsa VerifyEmailScreen'e yönlendir.
      final currentUser = svc.auth.currentUser;
      final needsVerification = currentUser != null &&
          !currentUser.isAnonymous &&
          !currentUser.emailVerified;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (_) => needsVerification
              ? const VerifyEmailScreen()
              : const MainScreen(),
        ),
        (_) => false,
      );
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      if (e.code == 'sign-in-cancelled') {
        return;
      }
      setState(() => _error = _mapAuthError(e));
    } catch (_) {
      if (!mounted) return;
      setState(() => _error = 'Google ile giriş yapılamadı.');
    } finally {
      if (mounted) setState(() => _submitting = false);
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
      await state.refreshFromAuthSession(preserveGuestAcknowledged: true);
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const MainScreen()),
        (_) => false,
      );
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
      case 'username-taken':
        return 'Bu kullanıcı adı zaten alınmış. Lütfen farklı bir tane seç.';
      case 'invalid-username':
        return e.message ??
            'Kullanıcı adı 3-20 karakter, sadece harf/rakam/_ olabilir.';
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
                  SizedBox(
                    height: 56,
                    child: Image.asset(
                      'assets/images/fiyatradar_logo.png',
                      fit: BoxFit.contain,
                      alignment: Alignment.centerLeft,
                    ),
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
                          _field(
                            controller: _usernameCtrl,
                            hint: 'Takma ad (kullanıcı adı)',
                            icon: Icons.alternate_email_rounded,
                            validator: (v) {
                              if (!_registerMode) return null;
                              final value = v?.trim() ?? '';
                              if (value.length < 3) {
                                return 'Takma ad en az 3 karakter olmalı.';
                              }
                              if (!RegExp(r'^@?[a-zA-Z0-9_]+$').hasMatch(value)) {
                                return 'Sadece harf, rakam ve _ kullan.';
                              }
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
                          onSubmitted: _registerMode ? null : (_) => _submit(),
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
                        if (_registerMode) ...[
                          const SizedBox(height: 10),
                          _field(
                            controller: _passwordConfirmCtrl,
                            hint: 'Şifre tekrar',
                            icon: Icons.lock_reset_rounded,
                            obscure: _obscure,
                            onSubmitted: (_) => _submit(),
                            validator: (v) {
                              if (!_registerMode) return null;
                              if (v == null || v.isEmpty) {
                                return 'Şifreyi tekrar gir.';
                              }
                              if (v.trim() != _passwordCtrl.text.trim()) {
                                return 'Şifreler eşleşmiyor.';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 12),
                          _ConsentRow(
                            value: _consentAccepted,
                            onChanged: (v) =>
                                setState(() => _consentAccepted = v ?? false),
                          ),
                        ],
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
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(child: Divider(color: FR.hairline, height: 1)),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 10),
                              child: Text(
                                'veya',
                                style: frText(11, FontWeight.w700, color: FR.ink3),
                              ),
                            ),
                            Expanded(child: Divider(color: FR.hairline, height: 1)),
                          ],
                        ),
                        const SizedBox(height: 12),
                        FRCta(
                          label: _registerMode
                              ? 'Google ile kayıt ol'
                              : 'Google ile giriş yap',
                          icon: Icons.g_mobiledata_rounded,
                          filled: false,
                          onTap: _submitting ? null : _signInWithGoogle,
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
                                  // Reset register-only state when toggling
                                  // back to login mode so a stale checkbox /
                                  // confirm value can't carry over.
                                  if (!_registerMode) {
                                    _consentAccepted = false;
                                    _passwordConfirmCtrl.clear();
                                  }
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

/// KVKK / consent row that gates the register CTA. Tapping a link opens
/// the legal text in the system browser; the checkbox itself records the
/// user's affirmative acceptance which we persist alongside the user doc.
class _ConsentRow extends StatelessWidget {
  const _ConsentRow({required this.value, required this.onChanged});
  final bool value;
  final ValueChanged<bool?> onChanged;

  Future<void> _open(BuildContext context, String url) async {
    final uri = Uri.parse(url);
    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bağlantı açılamadı.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Checkbox(
          value: value,
          onChanged: onChanged,
          side: BorderSide(color: FR.hairline, width: 1.4),
          activeColor: FR.gold,
          checkColor: FR.onGold,
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text(
                  '18 yaşından büyüğüm; ',
                  style: frText(11.5, FontWeight.w600, color: FR.ink2, height: 1.5),
                ),
                InkWell(
                  onTap: () => _open(context, _kSozlesmeUrl),
                  child: Text(
                    'Kullanıcı Sözleşmesi',
                    style: frText(11.5, FontWeight.w800, color: FR.gold, height: 1.5),
                  ),
                ),
                Text(' ve ',
                    style: frText(11.5, FontWeight.w600, color: FR.ink2, height: 1.5)),
                InkWell(
                  onTap: () => _open(context, _kGizlilikUrl),
                  child: Text(
                    'Gizlilik Politikası',
                    style: frText(11.5, FontWeight.w800, color: FR.gold, height: 1.5),
                  ),
                ),
                Text(
                  '\'nı okudum, kabul ediyorum (KVKK).',
                  style: frText(11.5, FontWeight.w600, color: FR.ink2, height: 1.5),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
