import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../state/app_state.dart';
import '../ui/components.dart';
import '../ui/tokens.dart';

/// E-posta/şifre ile kayıt olan kullanıcı katkı yapabilmek için önce
/// e-posta adresini doğrulamak zorunda. AuthGate doğrulanmamış kullanıcıyı
/// bu ekrana yönlendirir.
///
/// Akış:
///   • Kullanıcı kayıt olunca Firebase Auth otomatik doğrulama maili gönderir
///     (FirebaseService.registerWithEmail).
///   • Bu ekranda "Doğruladım" → `state.reloadAndCheckVerification()` çağrılır.
///   • "Tekrar gönder" cooldown'lu — spam'i engellemek için 60 sn boyunca
///     buton disabled.
///   • "Çıkış yap" oturumu kapatır; kullanıcı farklı bir hesapla devam
///     edebilir.
class VerifyEmailScreen extends StatefulWidget {
  const VerifyEmailScreen({super.key});

  @override
  State<VerifyEmailScreen> createState() => _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends State<VerifyEmailScreen> {
  bool _checking = false;
  bool _sending = false;
  String? _info;
  String? _error;
  Timer? _cooldownTicker;

  @override
  void initState() {
    super.initState();
    // Cooldown sayacı UI'da geri sayım göstermek için her saniye tikler;
    // cooldown bittiğinde kendiliğinden durur.
    _cooldownTicker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      final state = AppStateScope.read(context);
      if (state.verificationEmailCooldownRemaining == Duration.zero) {
        _cooldownTicker?.cancel();
        _cooldownTicker = null;
      }
      setState(() {});
    });
  }

  @override
  void dispose() {
    _cooldownTicker?.cancel();
    super.dispose();
  }

  Future<void> _checkVerification(AppState state) async {
    if (_checking) return;
    setState(() {
      _checking = true;
      _error = null;
      _info = null;
    });
    try {
      final verified = await state.reloadAndCheckVerification();
      if (!mounted) return;
      if (!verified) {
        setState(() {
          _info = 'Henüz doğrulanmamış. Mail kutunu kontrol edip linke '
              'tıkladıktan sonra tekrar dene.';
        });
      }
      // Doğrulandıysa AuthGate state notify ile MainScreen'e geçer; ayrı
      // bir navigation gerektirmez.
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'Doğrulama durumu alınamadı. Bağlantını kontrol et.';
      });
    } finally {
      if (mounted) setState(() => _checking = false);
    }
  }

  Future<void> _resendEmail(AppState state) async {
    if (_sending) return;
    setState(() {
      _sending = true;
      _error = null;
      _info = null;
    });
    try {
      await state.sendVerificationEmail();
      if (!mounted) return;
      setState(() {
        _info = 'Doğrulama maili tekrar gönderildi. Spam klasörünü de kontrol et.';
      });
      _ensureCooldownTickerRunning();
    } on StateError catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.message;
      });
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = _mapAuthError(e);
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'Mail gönderilemedi. Lütfen tekrar dene.';
      });
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  void _ensureCooldownTickerRunning() {
    _cooldownTicker?.cancel();
    _cooldownTicker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      final state = AppStateScope.read(context);
      if (state.verificationEmailCooldownRemaining == Duration.zero) {
        _cooldownTicker?.cancel();
        _cooldownTicker = null;
      }
      setState(() {});
    });
  }

  Future<void> _logout(AppState state) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: FR.surface,
        title: Text('Çıkış yap', style: frDisplay(20, FontWeight.w700)),
        content: Text(
          'Doğrulama tamamlanmadan çıkmak istediğine emin misin? '
          'Hesabını yine açıp doğrulama linkine tıklayabilirsin.',
          style: frText(12.5, FontWeight.w600, color: FR.ink2, height: 1.45),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Vazgeç',
                style: frText(13, FontWeight.w800, color: FR.ink3)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('Çıkış yap',
                style: frText(13, FontWeight.w800, color: FR.bad)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await state.logout();
  }

  String _mapAuthError(FirebaseAuthException e) {
    switch (e.code) {
      case 'too-many-requests':
        return 'Çok fazla deneme yapıldı. Birkaç dakika sonra tekrar dene.';
      case 'network-request-failed':
        return 'Bağlantı koptu. İnternetini kontrol et.';
      default:
        return 'Mail gönderilemedi. Lütfen tekrar dene.';
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = AppStateScope.of(context);
    final email = state.user?.email ?? '';
    final cooldown = state.verificationEmailCooldownRemaining;
    final cooldownSeconds = cooldown.inSeconds;
    final resendDisabled = _sending || cooldownSeconds > 0;

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
                  Center(
                    child: Container(
                      width: 96,
                      height: 96,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [FR.goldHi, FR.goldDeep],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: FRRad.all(28),
                        boxShadow: frGoldGlow(opacity: .28),
                      ),
                      child: Icon(Icons.mark_email_unread_rounded,
                          color: FR.onGold, size: 40),
                    ),
                  ),
                  const SizedBox(height: 22),
                  Text('DOĞRULAMA', style: frOverline()),
                  const SizedBox(height: 6),
                  Text(
                    'E-posta adresini doğrula',
                    style: frDisplay(28, FontWeight.w700),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Fiyat eklemek ve topluluğa katkı yapmak için '
                    'e-posta adresini doğrulaman gerekiyor.',
                    style: frText(13, FontWeight.w500,
                        color: FR.ink3, height: 1.5),
                  ),
                  if (email.isNotEmpty) ...[
                    const SizedBox(height: 18),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: FR.surface,
                        borderRadius: FRRad.all(FRRad.m),
                        border: Border.all(color: FR.hairline),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.alternate_email_rounded,
                              size: 18, color: FR.ink3),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              email,
                              style:
                                  frText(13.5, FontWeight.w700, color: FR.ink),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 20),
                  if (_info != null)
                    Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        color: FR.gold.withOpacity(.10),
                        borderRadius: FRRad.all(FRRad.m),
                        border: Border.all(color: FR.gold.withOpacity(.35)),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.info_outline_rounded,
                              color: FR.goldDeep, size: 18),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(_info!,
                                style: frText(12, FontWeight.w700,
                                    color: FR.goldDeep)),
                          ),
                        ],
                      ),
                    ),
                  if (_error != null)
                    Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        color: FR.bad.withOpacity(.10),
                        borderRadius: FRRad.all(FRRad.m),
                        border: Border.all(color: FR.bad.withOpacity(.35)),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.error_outline_rounded,
                              color: FR.bad, size: 18),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(_error!,
                                style: frText(12, FontWeight.w700,
                                    color: FR.bad)),
                          ),
                        ],
                      ),
                    ),
                  FRCta(
                    label: _checking ? 'Kontrol ediliyor…' : 'Doğruladım',
                    icon: Icons.check_circle_outline_rounded,
                    onTap: _checking ? null : () => _checkVerification(state),
                  ),
                  const SizedBox(height: 12),
                  FRCta(
                    label: _sending
                        ? 'Gönderiliyor…'
                        : (cooldownSeconds > 0
                            ? 'Tekrar gönder (${cooldownSeconds}s)'
                            : 'Doğrulama mailini tekrar gönder'),
                    icon: Icons.outgoing_mail,
                    filled: false,
                    onTap: resendDisabled ? null : () => _resendEmail(state),
                  ),
                  const SizedBox(height: 24),
                  Center(
                    child: TextButton(
                      onPressed: () => _logout(state),
                      child: Text(
                        'Çıkış yap',
                        style: frText(12.5, FontWeight.w800, color: FR.bad),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Center(
                    child: Text(
                      'Mail gelmediyse spam klasörünü kontrol et. '
                      'Doğrulama linkine tıkladıktan sonra bu ekranda '
                      '"Doğruladım" butonuna bas.',
                      textAlign: TextAlign.center,
                      style: frText(11.5, FontWeight.w600,
                          color: FR.ink3, height: 1.5),
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
}
