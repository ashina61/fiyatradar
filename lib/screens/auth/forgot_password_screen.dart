import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../providers/auth_provider.dart';
import '../../providers/firebase_init_provider.dart';
import 'widgets/auth_portal_widgets.dart';

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _sendReset() async {
    if (!_formKey.currentState!.validate()) return;
    if (!ref.read(firebaseInitializedProvider)) {
      _show('Firebase bağlantısı kurulamadı. Lütfen internet bağlantınızı kontrol edin.');
      return;
    }

    setState(() => _isLoading = true);
    try {
      await ref.read(authServiceProvider).resetPassword(_emailController.text.trim());
      _show('Şifre sıfırlama bağlantısı gönderildi.');
      if (!mounted) return;
      context.pop();
    } on FirebaseAuthException catch (e) {
      _show(ref.read(authServiceProvider).getErrorMessage(e));
    } catch (_) {
      _show('E-posta gönderilemedi.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _show(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), behavior: SnackBarBehavior.floating));
  }

  @override
  Widget build(BuildContext context) {
    return AuthSurface(
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AuthTopBackButton(onTap: () => context.pop()),
            const SizedBox(height: 22),
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: authWhite,
                borderRadius: BorderRadius.circular(24),
                boxShadow: const [BoxShadow(color: Color.fromRGBO(28, 17, 8, .08), blurRadius: 30, offset: Offset(0, 12))],
              ),
              child: const Icon(Icons.lock_reset_rounded, size: 40, color: authCamel),
            ),
            const SizedBox(height: 32),
            const AuthHeaderTexts(
              title: 'Şifreni mi\nUnuttun?',
              subtitle: 'Endişelenme. E-posta adresini gir, sana kokpite yeniden girmen için bir bağlantı gönderelim.',
            ),
            const SizedBox(height: 32),
            AuthInputField(
              label: 'Kayıtlı E-Posta',
              hint: 'ajan@fiyatradar.com',
              icon: Icons.mail_outline_rounded,
              keyboardType: TextInputType.emailAddress,
              controller: _emailController,
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Lütfen e-posta girin';
                if (!v.contains('@')) return 'Geçerli bir e-posta girin';
                return null;
              },
            ),
            const SizedBox(height: 32),
            MassivePrimaryButton(label: 'Bağlantı Gönder', onPressed: _sendReset, loading: _isLoading, icon: Icons.send_rounded),
          ],
        ),
      ),
    );
  }
}
