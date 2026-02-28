import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:geocoding/geocoding.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../providers/profile_provider.dart';
import '../../services/location_service.dart';
import '../../utils/cities_tr.dart';

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
  final _districtCtrl = TextEditingController();
  final _neighborhoodCtrl = TextEditingController();
  final LocationService _locationService = LocationService();
  bool _isInit = false;
  bool _isSaving = false;
  String _city = 'İstanbul';
  String? _photoUrl;

  List<String> get _cities => kCitiesTR.map((city) => city.name).toList(growable: false);

  @override
  void dispose() {
    _nameCtrl.dispose();
    _usernameCtrl.dispose();
    _districtCtrl.dispose();
    _neighborhoodCtrl.dispose();
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


  Future<void> _fillLocationFromCurrentPosition() async {
    setState(() => _isSaving = true);
    try {
      final position = await _locationService.getCurrentPosition();
      if (position == null) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Konum alınamadı. Lütfen konum izni verin.'), backgroundColor: Color(0xFFDC2626)),
        );
        return;
      }

      final placemarks = await placemarkFromCoordinates(position.latitude, position.longitude);
      if (placemarks.isEmpty) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Konum adres detayına çevrilemedi.'), backgroundColor: Color(0xFFDC2626)),
        );
        return;
      }

      final place = placemarks.first;
      final cityCandidate = (place.administrativeArea ?? place.locality ?? '').trim();
      final districtCandidate = (place.subAdministrativeArea ?? place.locality ?? '').trim();
      final neighborhoodCandidate = (place.subLocality ?? place.street ?? place.name ?? '').trim();

      setState(() {
        if (_cities.contains(cityCandidate)) {
          _city = cityCandidate;
        }
        _districtCtrl.text = districtCandidate;
        _neighborhoodCtrl.text = neighborhoodCandidate;
      });
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Konum bilgisi alınırken hata oluştu.'), backgroundColor: Color(0xFFDC2626)),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _save(user) async {
    setState(() => _isSaving = true);
    final fullName = _nameCtrl.text.trim();
    final district = _districtCtrl.text.trim();
    final neighborhood = _neighborhoodCtrl.text.trim();
    final selectedCity = kCitiesTR.where((city) => city.name == _city);
    final cityCode = selectedCity.isEmpty ? null : selectedCity.first.code;

    if (district.isEmpty || neighborhood.isEmpty) {
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('İlçe ve mahalle alanları boş bırakılamaz.'), backgroundColor: Color(0xFFDC2626)),
      );
      return;
    }

    final updatedUser = user.copyWith(
      name: fullName,
      username: _usernameCtrl.text.trim(),
      cityCode: cityCode,
      city: _city,
      cityName: _city,
      district: district,
      neighborhood: neighborhood,
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
            if (!_cities.contains(_city)) {
              _city = 'İstanbul';
            }
            _districtCtrl.text = user.district ?? '';
            _neighborhoodCtrl.text = user.neighborhood ?? '';
            _photoUrl = user.photoUrl;
            _isInit = true;
            if (_districtCtrl.text.trim().isEmpty || _neighborhoodCtrl.text.trim().isEmpty) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted) {
                  _fillLocationFromCurrentPosition();
                }
              });
            }
          }

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
                _dropdown('İl', _city, _cities, (value) => setState(() => _city = value)),
                _input(label: 'İlçe', controller: _districtCtrl, readOnly: true),
                _input(label: 'Mahalle', controller: _neighborhoodCtrl, readOnly: true),
                _locationFillTile(),
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

  Widget _input({required String label, required TextEditingController controller, bool readOnly = false}) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
      decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Color(0x148B4D22)))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 12, color: _sienna, fontWeight: FontWeight.w600)),
          TextField(
            controller: controller,
            readOnly: readOnly,
            decoration: const InputDecoration(border: InputBorder.none, isDense: true),
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }


  Widget _locationFillTile() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 14),
      decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Color(0x148B4D22)))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Konumdan Otomatik Doldur', style: TextStyle(fontSize: 12, color: _sienna, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _isSaving ? null : _fillLocationFromCurrentPosition,
              icon: const Icon(Icons.my_location_rounded),
              label: const Text('Mevcut konumu kullan (İl/İlçe/Mahalle)'),
              style: OutlinedButton.styleFrom(
                foregroundColor: _sienna,
                side: const BorderSide(color: Color(0x338B4D22)),
              ),
            ),
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
