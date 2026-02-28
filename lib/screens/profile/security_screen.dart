import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../widgets/animated_floating_input.dart';

class SecurityScreen extends StatefulWidget {
  const SecurityScreen({super.key});

  @override
  State<SecurityScreen> createState() => _SecurityScreenState();
}

class _SecurityScreenState extends State<SecurityScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final TextEditingController _emailCtrl = TextEditingController();
  final TextEditingController _passwordCtrl = TextEditingController();
  bool _isLoading = false;

  Future<void> _updateSecurity() async {
    setState(() => _isLoading = true);
    try {
      if (_emailCtrl.text.isNotEmpty && _emailCtrl.text != _auth.currentUser?.email) {
        await _auth.currentUser?.updateEmail(_emailCtrl.text.trim());
      }
      if (_passwordCtrl.text.isNotEmpty) {
        await _auth.currentUser?.updatePassword(_passwordCtrl.text.trim());
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Güvenlik bilgileri güncellendi!'), backgroundColor: Colors.green));
      }
      _passwordCtrl.clear();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Hata! (Yakın zamanda giriş yapmış olmanız gerekebilir)'), backgroundColor: Color(0xFFDC2626)));
      }
    }
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F3F0),
      appBar: AppBar(
        backgroundColor: Colors.white.withOpacity(0.95), elevation: 0, centerTitle: true, iconTheme: const IconThemeData(color: Color(0xFF8B4D22)),
        title: const Text('Güvenlik ve Giriş', style: TextStyle(color: Color(0xFF2D241E), fontSize: 17, fontWeight: FontWeight.w600)),
        bottom: PreferredSize(preferredSize: const Size.fromHeight(1), child: Container(color: const Color(0x148B4D22), height: 1)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Padding(padding: EdgeInsets.only(left: 16, bottom: 8), child: Text('E-POSTA YÖNETİMİ', style: TextStyle(color: Color(0xFF8E8A86), fontSize: 12, fontWeight: FontWeight.w600))),
          Container(
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: const Color(0x148B4D22))),
            child: Column(
              children: [
                AnimatedFloatingInput(label: 'Yeni E-Posta', controller: _emailCtrl),
                const Padding(
                  padding: EdgeInsets.only(left: 20, right: 20, bottom: 12),
                  child: Text('Mevcut: (Buraya mevcut mail gelecek)', style: TextStyle(color: Color(0xFF8E8A86), fontSize: 12)),
                )
              ],
            ),
          ),
          const SizedBox(height: 24),

          const Padding(padding: EdgeInsets.only(left: 16, bottom: 8), child: Text('ŞİFRE DEĞİŞTİR', style: TextStyle(color: Color(0xFF8E8A86), fontSize: 12, fontWeight: FontWeight.w600))),
          Container(
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: const Color(0x148B4D22))),
            child: Column(
              children: [
                AnimatedFloatingInput(label: 'Yeni Şifre Belirle', controller: _passwordCtrl, isPassword: true),
              ],
            ),
          ),
          const SizedBox(height: 32),
          
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF8B4D22), padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)), elevation: 0),
            onPressed: _isLoading ? null : _updateSecurity,
            child: _isLoading ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Text('Güvenlik Bilgilerini Güncelle', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white)),
          ),
          const SizedBox(height: 24),
          
          TextButton.icon(
            onPressed: () async {
              await _auth.signOut();
              // Çıkış yapınca Login ekranına yönlendirecek kodu buraya yazarsın.
            },
            icon: const Icon(Icons.logout, color: Color(0xFFDC2626)),
            label: const Text('Tüm Cihazlardan Çıkış Yap', style: TextStyle(color: Color(0xFFDC2626), fontSize: 15, fontWeight: FontWeight.w600)),
          )
        ],
      ),
    );
  }
}
