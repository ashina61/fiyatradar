import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../providers/auth_provider.dart';
import '../../providers/firebase_init_provider.dart';
import '../../theme/neo_design.dart';
import '../main_screen.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    if (!ref.read(firebaseInitializedProvider)) return _show('Sunucu bağlantısı kurulamadı.');
    setState(() => _loading = true);
    try {
      await ref.read(authNotifierProvider.notifier).signIn(email: _email.text.trim(), password: _password.text);
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(MaterialPageRoute(builder: (_) => const MainScreen()), (r) => false);
    } on FirebaseAuthException catch (e) {
      _show(ref.read(authServiceProvider).getErrorMessage(e));
    } catch (e) {
      _show('Giriş başarısız: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _show(String message) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: NeoScaffold(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 20),
                Text('Giriş Yap', style: NeoDesign.title()),
                const SizedBox(height: 6),
                Text('Yeni tasarım diliyle hızlı erişim.', style: NeoDesign.body()),
                const SizedBox(height: 24),
                TextFormField(controller: _email, decoration: NeoDesign.input('E-posta', icon: Icons.email_outlined)),
                const SizedBox(height: 12),
                TextFormField(controller: _password, obscureText: true, decoration: NeoDesign.input('Şifre', icon: Icons.lock_outline)),
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(onPressed: _loading ? null : _login, child: Text(_loading ? 'Bekleyin...' : 'Giriş')),
                ),
                TextButton(onPressed: () => context.push('/forgot-password'), child: const Text('Şifremi unuttum')),
                const Spacer(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('Hesabın yok mu? '),
                    TextButton(onPressed: () => context.push('/register'), child: const Text('Kayıt Ol')),
                  ],
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}
