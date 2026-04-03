import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/auth_provider.dart';
import '../../providers/firebase_init_provider.dart';
import '../../theme/neo_design.dart';

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _email = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    if (_email.text.trim().isEmpty) return;
    if (!ref.read(firebaseInitializedProvider)) return _show('Sunucu bağlantısı kurulamadı.');
    setState(() => _loading = true);
    try {
      await ref.read(authServiceProvider).resetPassword(_email.text.trim());
      _show('Sıfırlama bağlantısı gönderildi.');
      if (mounted) Navigator.pop(context);
    } on FirebaseAuthException catch (e) {
      _show(ref.read(authServiceProvider).getErrorMessage(e));
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.arrow_back, color: NeoDesign.text)),
              const SizedBox(height: 12),
              Text('Şifre Sıfırla', style: NeoDesign.title()),
              const SizedBox(height: 8),
              Text('E-posta adresini gir, sana yeni bağlantı yollayalım.', style: NeoDesign.body()),
              const SizedBox(height: 20),
              TextField(controller: _email, decoration: NeoDesign.input('E-posta', icon: Icons.email_outlined)),
              const SizedBox(height: 16),
              SizedBox(width: double.infinity, child: FilledButton(onPressed: _loading ? null : _send, child: const Text('Gönder'))),
            ],
          ),
        ),
      ),
    );
  }
}
