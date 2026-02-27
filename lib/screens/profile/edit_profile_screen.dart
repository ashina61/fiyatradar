import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../utils/cities_tr.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  static const _bgColor = Color(0xFFF7EFEA);
  static const _surfaceColor = Color(0xFFF4EAE3);
  static const _surfaceSoftColor = Color(0xFFF1E4DC);
  static const _textColor = Color(0xFF2B2B2B);
  static const _mutedColor = Color.fromRGBO(43, 43, 43, .55);
  static const _softBorder = Color.fromRGBO(43, 43, 43, .07);
  static const _accentColor = Color(0xFFB06A2B);
  static const _accentPressedColor = Color(0xFF995A24);

  final _displayNameController = TextEditingController();
  final _usernameController = TextEditingController();
  final _bioController = TextEditingController();
  CityTR? _selectedCity;

  bool _fiyatAlarm = true;
  bool _rozetBildirim = true;
  bool _kampanyaBildirim = true;
  bool _loading = true;
  bool _saving = false;
  String _email = '';
  bool _emailVerified = false;
  String _avatarUrl = '';
  File? _avatarFile;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      setState(() => _loading = false);
      return;
    }

    try {
      final docRef = FirebaseFirestore.instance.collection('users').doc(uid);
      final doc = await docRef.get();
      if (!doc.exists) {
        await docRef.set({
          'displayName': 'Kullanıcı',
          'photoUrl': '',
          'trustScore': 0,
          'verified': false,
          'levelName': 'Gözlemci',
          'notificationPrefs': {
            'priceAlerts': true,
            'badgeAlerts': true,
            'campaignAlerts': true,
          }
        }, SetOptions(merge: true));
      }
      final data = (await docRef.get()).data() ?? <String, dynamic>{};
      final prefs = Map<String, dynamic>.from(data['notificationPrefs'] ?? {});

      _displayNameController.text = (data['displayName'] ?? data['name'] ?? '').toString();
      _usernameController.text = (data['username'] ?? '').toString();
      _bioController.text = (data['bio'] ?? '').toString();
      final cityCode = (data['cityCode'] ?? '').toString();
      final cityName = (data['cityName'] ?? data['city'] ?? '').toString();
      for (final city in kCitiesTR) {
        if (city.code == cityCode || city.name == cityName) {
          _selectedCity = city;
          break;
        }
      }
      _avatarUrl = (data['photoUrl'] ?? '').toString();
      _fiyatAlarm = prefs['priceAlerts'] != false;
      _rozetBildirim = prefs['badgeAlerts'] != false;
      _kampanyaBildirim = prefs['campaignAlerts'] != false;
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Profil yüklenemedi.')));
      }
    }

    final user = FirebaseAuth.instance.currentUser;
    await user?.reload();
    _email = user?.email ?? '';
    _emailVerified = FirebaseAuth.instance.currentUser?.emailVerified ?? false;

    if (mounted) setState(() => _loading = false);
  }

  Future<void> _pickAvatar() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 82);
    if (picked == null) return;
    setState(() => _avatarFile = File(picked.path));
  }

  Future<String> _uploadAvatar(String uid) async {
    if (_avatarFile == null) return _avatarUrl;
    final ref = FirebaseStorage.instance.ref().child('users/$uid/avatar.jpg');
    await ref.putFile(_avatarFile!);
    return ref.getDownloadURL();
  }

  Future<void> _save() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    setState(() => _saving = true);

    try {
      final photoUrl = await _uploadAvatar(uid);
      final displayName = _displayNameController.text.trim();
      final username = _usernameController.text.trim();
      final publicName = username.isEmpty ? displayName : username;

      await FirebaseFirestore.instance.collection('users').doc(uid).set({
        'displayName': displayName,
        'name': publicName,
        'username': username,
        'bio': _bioController.text.trim(),
        'cityCode': _selectedCity?.code ?? '',
        'cityName': _selectedCity?.name ?? '',
        'city': _selectedCity?.name ?? '',
        'photoUrl': photoUrl,
        'notificationPrefs': {
          'priceAlerts': _fiyatAlarm,
          'badgeAlerts': _rozetBildirim,
          'campaignAlerts': _kampanyaBildirim,
        },
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      await FirebaseAuth.instance.currentUser?.updateDisplayName(publicName.isEmpty ? 'Kullanıcı' : publicName);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Profil güncellendi.')));
      Navigator.of(context).pop();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Profil güncellenemedi.')));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _sendVerificationMail() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    try {
      await user.sendEmailVerification();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Doğrulama e-postası gönderildi. Lütfen gelen kutunuzu kontrol edin.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('E-posta gönderilemedi. Lütfen tekrar deneyin.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _changePassword() async {
    final currentController = TextEditingController();
    final newController = TextEditingController();
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || user.email == null) return;

    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Şifre değiştir'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: currentController, obscureText: true, decoration: const InputDecoration(labelText: 'Mevcut şifre')),
            TextField(controller: newController, obscureText: true, decoration: const InputDecoration(labelText: 'Yeni şifre')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('İptal')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Değiştir')),
        ],
      ),
    );

    if (ok != true) return;

    try {
      final cred = EmailAuthProvider.credential(email: user.email!, password: currentController.text.trim());
      await user.reauthenticateWithCredential(cred);
      await user.updatePassword(newController.text.trim());
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Şifren güncellendi.')));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Şifre değiştirilemedi.')));
    }
  }

  Future<void> _deleteAccount() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || user.email == null) return;
    final passController = TextEditingController();

    final approved = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hesabı sil'),
        content: TextField(controller: passController, obscureText: true, decoration: const InputDecoration(labelText: 'Şifreni gir')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Vazgeç')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Kalıcı olarak sil')),
        ],
      ),
    );

    if (approved != true) return;

    try {
      final cred = EmailAuthProvider.credential(email: user.email!, password: passController.text.trim());
      await user.reauthenticateWithCredential(cred);
      await FirebaseFirestore.instance.collection('users').doc(user.uid).delete();
      await user.delete();
      if (!mounted) return;
      Navigator.of(context).popUntil((route) => route.isFirst);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Hesap silindi.')));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Hesap silinemedi.')));
    }
  }

  @override
  void dispose() {
    _displayNameController.dispose();
    _usernameController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ImageProvider<Object>? avatarImage;
    if (_avatarFile != null) {
      avatarImage = FileImage(_avatarFile!);
    } else if (_avatarUrl.isNotEmpty) {
      avatarImage = NetworkImage(_avatarUrl);
    }

    final baseInputDecoration = InputDecoration(
      labelStyle: const TextStyle(color: _mutedColor, fontSize: 13, fontWeight: FontWeight.w600),
      floatingLabelStyle: const TextStyle(color: _mutedColor, fontSize: 13, fontWeight: FontWeight.w600),
      hintStyle: const TextStyle(color: Color.fromRGBO(43, 43, 43, .35), fontSize: 16, fontWeight: FontWeight.w600),
      filled: true,
      fillColor: _surfaceColor,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(22),
        borderSide: const BorderSide(color: _softBorder),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(22),
        borderSide: const BorderSide(color: _softBorder),
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(22),
        borderSide: const BorderSide(color: _softBorder),
      ),
    );

    return Scaffold(
      backgroundColor: _bgColor,
      appBar: AppBar(
        title: const Text('Profili Düzenle', style: TextStyle(fontWeight: FontWeight.w700, color: _textColor)),
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.white,
        foregroundColor: _textColor,
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, thickness: 1, color: _softBorder),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Center(
                  child: GestureDetector(
                    onTap: _pickAvatar,
                    child: CircleAvatar(
                      radius: 48,
                      backgroundColor: _surfaceColor,
                      backgroundImage: avatarImage,
                      child: _avatarFile == null && _avatarUrl.isEmpty ? const Icon(Icons.add_a_photo_rounded, color: _mutedColor) : null,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _displayNameController,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: _textColor),
                  decoration: baseInputDecoration.copyWith(labelText: 'Ad Soyad', hintText: 'Adınızı girin'),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _usernameController,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: _textColor),
                  decoration: baseInputDecoration.copyWith(labelText: 'Kullanıcı adı (opsiyonel)'),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _bioController,
                  maxLines: 3,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: _textColor),
                  decoration: baseInputDecoration.copyWith(labelText: 'Biyografi (opsiyonel)'),
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<CityTR>(
                  value: _selectedCity,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: _textColor),
                  dropdownColor: _surfaceColor,
                  items: kCitiesTR
                      .map((city) => DropdownMenuItem<CityTR>(
                            value: city,
                            child: Text(city.name),
                          ))
                      .toList(),
                  onChanged: (value) => setState(() => _selectedCity = value),
                  decoration: baseInputDecoration.copyWith(labelText: 'Şehir'),
                ),
                const SizedBox(height: 14),
                Container(
                  decoration: BoxDecoration(
                    color: _surfaceColor,
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(color: _softBorder),
                  ),
                  child: Column(
                    children: [
                      _buildToggleRow(
                        title: 'Fiyat alarm bildirimleri',
                        value: _fiyatAlarm,
                        onChanged: (v) => setState(() => _fiyatAlarm = v),
                      ),
                      const Divider(height: 1, color: _softBorder),
                      _buildToggleRow(
                        title: 'Rozet bildirimleri',
                        value: _rozetBildirim,
                        onChanged: (v) => setState(() => _rozetBildirim = v),
                      ),
                      const Divider(height: 1, color: _softBorder),
                      _buildToggleRow(
                        title: 'Kampanya bildirimleri',
                        value: _kampanyaBildirim,
                        onChanged: (v) => setState(() => _kampanyaBildirim = v),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                Container(
                  decoration: BoxDecoration(
                    color: _surfaceSoftColor,
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(color: _softBorder),
                  ),
                  child: Column(
                    children: [
                      ListTile(
                        leading: Icon(_emailVerified ? Icons.verified : Icons.error_outline, color: _emailVerified ? Colors.green : Colors.orange),
                        title: Text(_email.isEmpty ? 'E-posta bulunamadı' : _email, style: const TextStyle(color: _textColor, fontWeight: FontWeight.w600)),
                        subtitle: Text(_emailVerified ? 'E-posta doğrulandı' : 'E-posta doğrulanmadı', style: const TextStyle(color: _mutedColor)),
                        trailing: _emailVerified
                            ? null
                            : TextButton(
                                onPressed: _sendVerificationMail,
                                child: const Text('Doğrulama e-postası gönder', style: TextStyle(color: _accentColor)),
                              ),
                      ),
                      const Divider(height: 1, color: _softBorder),
                      ListTile(
                        leading: const Icon(Icons.password_rounded, color: _textColor),
                        title: const Text('Şifre değiştir', style: TextStyle(color: _textColor, fontWeight: FontWeight.w600)),
                        onTap: _changePassword,
                      ),
                      const Divider(height: 1, color: _softBorder),
                      const ListTile(
                        leading: Icon(Icons.devices_rounded, color: _textColor),
                        title: Text('Oturumlar / cihazlar', style: TextStyle(color: _textColor, fontWeight: FontWeight.w600)),
                        subtitle: Text('Bu özellik yakında gelişmiş şekilde sunulacak.', style: TextStyle(color: _mutedColor)),
                      ),
                      const Divider(height: 1, color: _softBorder),
                      ListTile(
                        leading: const Icon(Icons.delete_forever_rounded, color: Colors.red),
                        title: const Text('Hesabı sil', style: TextStyle(color: _textColor, fontWeight: FontWeight.w600)),
                        onTap: _deleteAccount,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: _accentColor,
                    foregroundColor: Colors.white,
                    minimumSize: const Size.fromHeight(54),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                    elevation: 1,
                    shadowColor: _accentColor.withValues(alpha: .22),
                    textStyle: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
                  ).copyWith(
                    backgroundColor: WidgetStateProperty.resolveWith(
                      (states) => states.contains(WidgetState.pressed) ? _accentPressedColor : _accentColor,
                    ),
                  ),
                  onPressed: _saving ? null : _save,
                  child: _saving
                      ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Text('Kaydet'),
                ),
              ],
            ),
    );
  }

  Widget _buildToggleRow({
    required String title,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: const TextStyle(color: _textColor, fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: Colors.white,
            activeTrackColor: _accentColor,
            inactiveThumbColor: Colors.white,
            inactiveTrackColor: const Color(0x4A000000),
          ),
        ],
      ),
    );
  }
}
