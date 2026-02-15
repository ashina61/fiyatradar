import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _displayNameController = TextEditingController();
  final _usernameController = TextEditingController();
  final _bioController = TextEditingController();
  final _cityController = TextEditingController();

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
          'levelName': 'Elmas seviyesi',
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
      _cityController.text = (data['city'] ?? '').toString();
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
      await FirebaseFirestore.instance.collection('users').doc(uid).set({
        'displayName': _displayNameController.text.trim(),
        'username': _usernameController.text.trim(),
        'bio': _bioController.text.trim(),
        'city': _cityController.text.trim(),
        'photoUrl': photoUrl,
        'notificationPrefs': {
          'priceAlerts': _fiyatAlarm,
          'badgeAlerts': _rozetBildirim,
          'campaignAlerts': _kampanyaBildirim,
        },
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
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
    await user.sendEmailVerification();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Doğrulama e-postası gönderildi.')));
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
    _cityController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Profili Düzenle')),
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
                      backgroundImage: _avatarFile != null
                          ? FileImage(_avatarFile!)
                          : (_avatarUrl.isNotEmpty ? NetworkImage(_avatarUrl) : null),
                      child: _avatarFile == null && _avatarUrl.isEmpty ? const Icon(Icons.add_a_photo_rounded) : null,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(controller: _displayNameController, decoration: const InputDecoration(labelText: 'Ad Soyad')),
                const SizedBox(height: 10),
                TextField(controller: _usernameController, decoration: const InputDecoration(labelText: 'Kullanıcı adı (opsiyonel)')),
                const SizedBox(height: 10),
                TextField(controller: _bioController, maxLines: 3, decoration: const InputDecoration(labelText: 'Biyografi (opsiyonel)')),
                const SizedBox(height: 10),
                TextField(controller: _cityController, decoration: const InputDecoration(labelText: 'Şehir (opsiyonel)')),
                const SizedBox(height: 14),
                ExpansionTile(
                  title: const Text('Bildirim Tercihleri'),
                  initiallyExpanded: true,
                  children: [
                    SwitchListTile.adaptive(value: _fiyatAlarm, onChanged: (v) => setState(() => _fiyatAlarm = v), title: const Text('Fiyat alarm bildirimleri')),
                    SwitchListTile.adaptive(value: _rozetBildirim, onChanged: (v) => setState(() => _rozetBildirim = v), title: const Text('Rozet bildirimleri')),
                    SwitchListTile.adaptive(value: _kampanyaBildirim, onChanged: (v) => setState(() => _kampanyaBildirim = v), title: const Text('Kampanya bildirimleri')),
                  ],
                ),
                ExpansionTile(
                  title: const Text('Güvenlik'),
                  children: [
                    ListTile(
                      leading: Icon(_emailVerified ? Icons.verified : Icons.error_outline, color: _emailVerified ? Colors.green : Colors.orange),
                      title: Text(_email.isEmpty ? 'E-posta bulunamadı' : _email),
                      subtitle: Text(_emailVerified ? 'E-posta doğrulandı' : 'E-posta doğrulanmadı'),
                      trailing: _emailVerified ? null : TextButton(onPressed: _sendVerificationMail, child: const Text('Doğrula')),
                    ),
                    ListTile(leading: const Icon(Icons.password_rounded), title: const Text('Şifre değiştir'), onTap: _changePassword),
                    const ListTile(leading: Icon(Icons.devices_rounded), title: Text('Oturumlar / cihazlar'), subtitle: Text('Bu özellik yakında gelişmiş şekilde sunulacak.')),
                    ListTile(leading: const Icon(Icons.delete_forever_rounded, color: Colors.red), title: const Text('Hesabı sil'), onTap: _deleteAccount),
                  ],
                ),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: _saving ? null : _save,
                  child: _saving
                      ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Text('Kaydet'),
                ),
              ],
            ),
    );
  }
}
