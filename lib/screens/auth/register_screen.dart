import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../providers/auth_provider.dart';
import '../../providers/firebase_init_provider.dart';
import '../../theme/neo_design.dart';
import '../main_screen.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _username = TextEditingController();
  final _password = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _username.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;
    if (!ref.read(firebaseInitializedProvider)) return _show('Sunucu bağlantısı kurulamadı.');
    setState(() => _loading = true);
    try {
      await ref.read(authNotifierProvider.notifier).register(
            email: _email.text.trim(),
            password: _password.text,
            name: _name.text.trim(),
            username: _username.text.trim(),
            inviteCode: '',
            legalConsentVersion: 'v2.0',
          );
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(MaterialPageRoute(builder: (_) => const MainScreen()), (r) => false);
    } on FirebaseAuthException catch (e) {
      _show(ref.read(authServiceProvider).getErrorMessage(e));
    } catch (e) {
      _show('Kayıt başarısız: $e');
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
            child: ListView(
              children: [
                Text('Kayıt Ol', style: NeoDesign.title()),
                const SizedBox(height: 8),
                Text('Sıfırdan tasarlanan deneyime katıl.', style: NeoDesign.body()),
                const SizedBox(height: 24),
                TextFormField(controller: _name, decoration: NeoDesign.input('Ad Soyad', icon: Icons.person_outline)),
                const SizedBox(height: 12),
                TextFormField(controller: _username, decoration: NeoDesign.input('Kullanıcı adı', icon: Icons.alternate_email)),
                const SizedBox(height: 12),
                TextFormField(controller: _email, decoration: NeoDesign.input('E-posta', icon: Icons.email_outlined)),
                const SizedBox(height: 12),
                TextFormField(controller: _password, obscureText: true, decoration: NeoDesign.input('Şifre', icon: Icons.lock_outline)),
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(onPressed: _loading ? null : _register, child: Text(_loading ? 'Bekleyin...' : 'Hesap Oluştur')),
                ),
                TextButton(onPressed: () => context.go('/login'), child: const Text('Zaten hesabım var')),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
