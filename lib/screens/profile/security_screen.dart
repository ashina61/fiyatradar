import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class SecurityScreen extends StatefulWidget {
  const SecurityScreen({super.key});

  @override
  State<SecurityScreen> createState() => _SecurityScreenState();
}

class _SecurityScreenState extends State<SecurityScreen> {
  static const _sienna = Color(0xFF8B4D22);

  final _auth = FirebaseAuth.instance;
  final _newEmailCtrl = TextEditingController();
  final _currentPasswordCtrl = TextEditingController();
  final _newPasswordCtrl = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _newEmailCtrl.dispose();
    _currentPasswordCtrl.dispose();
    _newPasswordCtrl.dispose();
    super.dispose();
  }

  Future<void> _saveSecurity() async {
    final user = _auth.currentUser;
    if (user == null) return;

    setState(() => _isLoading = true);
    try {
      final currentPassword = _currentPasswordCtrl.text.trim();
      if (currentPassword.isNotEmpty && user.email != null) {
        final credential = EmailAuthProvider.credential(email: user.email!, password: currentPassword);
        await user.reauthenticateWithCredential(credential);
      }

      final newEmail = _newEmailCtrl.text.trim();
      if (newEmail.isNotEmpty && newEmail != user.email) {
        await user.verifyBeforeUpdateEmail(newEmail);
      }

      final newPassword = _newPasswordCtrl.text.trim();
      if (newPassword.isNotEmpty) {
        await user.updatePassword(newPassword);
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Güvenlik bilgileri güncellendi.')),
      );
      Navigator.pop(context);
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.message ?? 'Güncelleme başarısız.'),
          backgroundColor: const Color(0xFFDC2626),
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentEmail = _auth.currentUser?.email ?? '-';

    return Scaffold(
      backgroundColor: const Color(0xFFF5F3F0),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFDFBF9).withOpacity(0.95),
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: _sienna),
        title: const Text('Güvenlik ve Giriş', style: TextStyle(color: Color(0xFF2D241E), fontSize: 17, fontWeight: FontWeight.w600)),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
        children: [
          const Padding(
            padding: EdgeInsets.only(left: 12, bottom: 8),
            child: Text('E-POSTA YÖNETİMİ', style: TextStyle(color: Color(0xFF8E8A86), fontSize: 13, fontWeight: FontWeight.w700)),
          ),
          _group([
            _field('Mevcut E-Posta', initialValue: currentEmail, enabled: false),
            _field('Yeni E-Posta Adresi', controller: _newEmailCtrl, hintText: 'yeni@email.com'),
          ]),
          const SizedBox(height: 20),
          const Padding(
            padding: EdgeInsets.only(left: 12, bottom: 8),
            child: Text('ŞİFRE DEĞİŞTİR', style: TextStyle(color: Color(0xFF8E8A86), fontSize: 13, fontWeight: FontWeight.w700)),
          ),
          _group([
            _field('Mevcut Şifre', controller: _currentPasswordCtrl, obscureText: true, hintText: '••••••••'),
            _field('Yeni Şifre', controller: _newPasswordCtrl, obscureText: true, hintText: '••••••••'),
          ]),
          const SizedBox(height: 24),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: _sienna,
              foregroundColor: Colors.white,
              minimumSize: const Size(double.infinity, 58),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
            ),
            onPressed: _isLoading ? null : _saveSecurity,
            child: _isLoading
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Text('Güvenlik Bilgilerini Güncelle', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  Widget _group(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0x148B4D22)),
      ),
      child: Column(children: children),
    );
  }

  Widget _field(
    String label, {
    TextEditingController? controller,
    String? initialValue,
    String? hintText,
    bool enabled = true,
    bool obscureText = false,
  }) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
      decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Color(0x148B4D22)))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 12, color: _sienna, fontWeight: FontWeight.w600)),
          TextFormField(
            controller: controller,
            initialValue: initialValue,
            enabled: enabled,
            obscureText: obscureText,
            decoration: InputDecoration(
              border: InputBorder.none,
              hintText: hintText,
            ),
            style: TextStyle(fontSize: 16, color: enabled ? const Color(0xFF2D241E) : const Color(0xFF8E8A86), fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }
}
