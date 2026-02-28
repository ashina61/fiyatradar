import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
// KENDİ PROJENE GÖRE BU YOLLARI DÜZELT:
import '../../providers/profile_provider.dart'; 
import '../../widgets/animated_floating_input.dart'; 

class PersonalInfoScreen extends ConsumerStatefulWidget {
  const PersonalInfoScreen({super.key});

  @override
  ConsumerState<PersonalInfoScreen> createState() => _PersonalInfoScreenState();
}

class _PersonalInfoScreenState extends ConsumerState<PersonalInfoScreen> {
  final TextEditingController _nameCtrl = TextEditingController();
  final TextEditingController _surnameCtrl = TextEditingController();
  final TextEditingController _usernameCtrl = TextEditingController();
  
  bool _isInit = false; // Verileri sadece ilk açılışta inputlara yazmak için

  @override
  void dispose() {
    _nameCtrl.dispose();
    _surnameCtrl.dispose();
    _usernameCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // FİREBASE'İ CANLI DİNLİYORUZ!
    final profileState = ref.watch(profileProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F3F0),
      appBar: AppBar(
        backgroundColor: Colors.white.withOpacity(0.95),
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Color(0xFF8B4D22)),
        title: const Text('Kişisel Bilgiler', style: TextStyle(color: Color(0xFF2D241E), fontSize: 17, fontWeight: FontWeight.w600)),
        bottom: PreferredSize(preferredSize: const Size.fromHeight(1), child: Container(color: const Color(0x148B4D22), height: 1)),
      ),
      
      // RIVERPOD BÜYÜSÜ: Veri durumuna göre ekran değişiyor
      body: profileState.when(
        loading: () => const Center(child: CircularProgressIndicator(color: Color(0xFF8B4D22))),
        error: (error, stack) => Center(child: Text('Hata oluştu:\n$error', textAlign: TextAlign.center)),
        data: (user) {
          if (user == null) {
            return const Center(child: Text('Profil bulunamadı. Lütfen giriş yapın.', style: TextStyle(color: Color(0xFF8E8A86))));
          }

          // Veri geldiğinde inputlara bas (Sadece 1 kere)
          if (!_isInit) {
            _nameCtrl.text = user.name;
            _surnameCtrl.text = user.surname;
            _usernameCtrl.text = user.username ?? '';
            _isInit = true;
          }

          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              const Padding(
                padding: EdgeInsets.only(left: 16, bottom: 8), 
                child: Text('TEMEL BİLGİLER', style: TextStyle(color: Color(0xFF8E8A86), fontSize: 12, fontWeight: FontWeight.w600))
              ),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white, 
                  borderRadius: BorderRadius.circular(20), 
                  border: Border.all(color: const Color(0x148B4D22))
                ),
                child: Column(
                  children: [
                    AnimatedFloatingInput(label: 'Ad', controller: _nameCtrl),
                    const Divider(height: 1, color: Color(0x148B4D22), indent: 20),
                    AnimatedFloatingInput(label: 'Soyad', controller: _surnameCtrl),
                    const Divider(height: 1, color: Color(0x148B4D22), indent: 20),
                    AnimatedFloatingInput(label: 'Kullanıcı Adı', controller: _usernameCtrl),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF8B4D22), 
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 0,
                ),
                onPressed: () async {
                  // Firebase'e Güncelleme İsteği At!
                  final updatedUser = user.copyWith(
                    name: _nameCtrl.text.trim(),
                    surname: _surnameCtrl.text.trim(),
                    username: _usernameCtrl.text.trim(),
                  );
                  
                  final success = await ref.read(profileProvider.notifier).updateProfile(updatedUser);
                  
                  if (success && context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Profil başarıyla güncellendi!'), backgroundColor: Colors.green));
                    Navigator.pop(context);
                  }
                },
                child: const Text('Değişiklikleri Kaydet', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white)),
              )
            ],
          );
        },
      ),
    );
  }
}
