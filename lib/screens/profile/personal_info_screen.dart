import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../providers/profile_provider.dart';

class PersonalInfoScreen extends ConsumerStatefulWidget {
  const PersonalInfoScreen({super.key});

  @override
  ConsumerState<PersonalInfoScreen> createState() => _PersonalInfoScreenState();
}

class _PersonalInfoScreenState extends ConsumerState<PersonalInfoScreen> {
  static const _sienna = Color(0xFF8B4D22);
  static const _muted = Color(0xFF8E8A86);

  final _nameCtrl = TextEditingController();
  final _usernameCtrl = TextEditingController();
  bool _isInit = false;
  bool _isSaving = false;
  String _city = 'İstanbul';
  String _district = 'Kadıköy';
  String _neighborhood = 'Cumhuriyet Mah.';
  String? _photoUrl;

  final Map<String, Map<String, List<String>>> _locations = const {
    'İstanbul': {
      'Kadıköy': ['Cumhuriyet Mah.', 'Caferağa Mah.', 'Osmanağa Mah.'],
      'Beşiktaş': ['Abbasağa Mah.', 'Levent Mah.', 'Vişnezade Mah.'],
      'Üsküdar': ['Altunizade Mah.', 'Mimar Sinan Mah.', 'Acıbadem Mah.'],
    },
    'Ankara': {
      'Çankaya': ['Kızılay Mah.', 'Bahçelievler Mah.', 'Ayrancı Mah.'],
      'Keçiören': ['Etlik Mah.', 'Aşağı Eğlence Mah.', 'Bağlum Mah.'],
    },
    'İzmir': {
      'Karşıyaka': ['Bostanlı Mah.', 'Mavişehir Mah.', 'Yalı Mah.'],
      'Bornova': ['Kazımdirik Mah.', 'Erzene Mah.', 'Atatürk Mah.'],
    },
  };

  @override
  void dispose() {
    _nameCtrl.dispose();
    _usernameCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    final image = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 80, maxWidth: 1200);
    if (image == null) return;

    setState(() => _isSaving = true);
    try {
      final refStorage = FirebaseStorage.instance.ref('profile_photos/$uid.jpg');
      await refStorage.putFile(File(image.path));
      final downloadUrl = await refStorage.getDownloadURL();
      setState(() => _photoUrl = downloadUrl);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Fotoğraf yüklenemedi.'), backgroundColor: Color(0xFFDC2626)),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _save(user) async {
    setState(() => _isSaving = true);
    final fullName = _nameCtrl.text.trim();
    final updatedUser = user.copyWith(
      name: fullName,
      username: _usernameCtrl.text.trim(),
      city: _city,
      cityName: _city,
      district: _district,
      neighborhood: _neighborhood,
      photoUrl: _photoUrl,
    );
    final success = await ref.read(profileProvider.notifier).updateProfile(updatedUser);
    if (mounted) {
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success ? 'Profil güncellendi.' : 'Profil güncellenemedi.'),
          backgroundColor: success ? Colors.green : const Color(0xFFDC2626),
        ),
      );
      if (success) Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final profileState = ref.watch(profileProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F3F0),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFDFBF9).withOpacity(0.95),
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: _sienna),
        title: const Text('Kişisel Bilgiler', style: TextStyle(color: Color(0xFF2D241E), fontSize: 17, fontWeight: FontWeight.w600)),
      ),
      body: profileState.when(
        loading: () => const Center(child: CircularProgressIndicator(color: _sienna)),
        error: (error, _) => Center(child: Text('Hata oluştu: $error')),
        data: (user) {
          if (user == null) return const Center(child: Text('Profil bulunamadı.'));

          if (!_isInit) {
            _nameCtrl.text = user.name;
            _usernameCtrl.text = user.username ?? '';
            _city = (user.city ?? 'İstanbul');
            _district = (user.district ?? _locations[_city]!.keys.first);
            _neighborhood = user.neighborhood ?? _locations[_city]![_district]!.first;
            _photoUrl = user.photoUrl;
            _isInit = true;
          }

          final cityDistricts = _locations[_city]!.keys.toList();
          if (!cityDistricts.contains(_district)) _district = cityDistricts.first;
          final districtNeighborhoods = _locations[_city]![_district]!;
          if (!districtNeighborhoods.contains(_neighborhood)) _neighborhood = districtNeighborhoods.first;

          final initials = _nameCtrl.text.trim().isEmpty
              ? 'FR'
              : _nameCtrl.text.trim().split(RegExp(r'\s+')).take(2).map((e) => e[0].toUpperCase()).join();

          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
            children: [
              Center(
                child: Column(
                  children: [
                    Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Container(
                          width: 88,
                          height: 88,
                          decoration: BoxDecoration(color: const Color(0x1A8B4D22), borderRadius: BorderRadius.circular(28)),
                          alignment: Alignment.center,
                          child: _photoUrl == null || _photoUrl!.isEmpty
                              ? Text(initials, style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w700, color: _sienna))
                              : ClipRRect(
                                  borderRadius: BorderRadius.circular(28),
                                  child: Image.network(_photoUrl!, width: 88, height: 88, fit: BoxFit.cover),
                                ),
                        ),
                        Positioned(
                          right: -6,
                          bottom: -6,
                          child: InkWell(
                            onTap: _pickPhoto,
                            child: Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                                border: Border.all(color: const Color(0x148B4D22)),
                                boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 8)],
                              ),
                              child: const Icon(Icons.photo_camera_outlined, size: 16),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Text('Fotoğrafı Değiştir', style: TextStyle(color: _sienna, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              const Padding(
                padding: EdgeInsets.only(left: 12, bottom: 8),
                child: Text('TEMEL BİLGİLER', style: TextStyle(color: _muted, fontSize: 13, fontWeight: FontWeight.w700)),
              ),
              _group([
                _input(label: 'Ad Soyad', controller: _nameCtrl),
                _input(label: 'Kullanıcı Adı', controller: _usernameCtrl),
              ]),
              const SizedBox(height: 20),
              const Padding(
                padding: EdgeInsets.only(left: 12, bottom: 8),
                child: Text('KONUM (MARKET ÖNERİLERİ İÇİN)', style: TextStyle(color: _muted, fontSize: 13, fontWeight: FontWeight.w700)),
              ),
              _group([
                _dropdown('İl', _city, _locations.keys.toList(), (value) {
                  setState(() {
                    _city = value;
                    _district = _locations[_city]!.keys.first;
                    _neighborhood = _locations[_city]![_district]!.first;
                  });
                }),
                _dropdown('İlçe', _district, cityDistricts, (value) {
                  setState(() {
                    _district = value;
                    _neighborhood = _locations[_city]![_district]!.first;
                  });
                }),
                _dropdown('Mahalle', _neighborhood, districtNeighborhoods, (value) => setState(() => _neighborhood = value)),
              ]),
              const SizedBox(height: 24),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: _sienna,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  minimumSize: const Size(double.infinity, 58),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                ),
                onPressed: _isSaving ? null : () => _save(user),
                child: _isSaving
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text('Değişiklikleri Kaydet', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
              ),
            ],
          );
        },
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

  Widget _input({required String label, required TextEditingController controller}) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
      decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Color(0x148B4D22)))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 12, color: _sienna, fontWeight: FontWeight.w600)),
          TextField(
            controller: controller,
            decoration: const InputDecoration(border: InputBorder.none, isDense: true),
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  Widget _dropdown(String label, String value, List<String> items, ValueChanged<String> onChanged) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
      decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Color(0x148B4D22)))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 12, color: _sienna, fontWeight: FontWeight.w600)),
          DropdownButton<String>(
            value: value,
            isExpanded: true,
            underline: const SizedBox.shrink(),
            icon: const Icon(Icons.keyboard_arrow_down_rounded, color: _sienna),
            items: items.map((e) => DropdownMenuItem(value: e, child: Text(e, style: const TextStyle(fontSize: 16)))).toList(),
            onChanged: (newValue) {
              if (newValue != null) onChanged(newValue);
            },
          ),
        ],
      ),
    );
  }
}
