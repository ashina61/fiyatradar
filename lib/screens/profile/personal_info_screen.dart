import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../models/user_model.dart';
import '../../providers/profile_provider.dart';
import '../../theme/fr_colors.dart';

class PersonalInfoScreen extends ConsumerStatefulWidget {
  const PersonalInfoScreen({super.key});

  @override
  ConsumerState<PersonalInfoScreen> createState() => _PersonalInfoScreenState();
}

class _PersonalInfoScreenState extends ConsumerState<PersonalInfoScreen> {
  final _nameController = TextEditingController();
  final _usernameController = TextEditingController();
  bool _didInit = false;
  bool _isSaving = false;
  String? _photoUrl;

  @override
  void dispose() {
    _nameController.dispose();
    _usernameController.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final image = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
      maxWidth: 1400,
    );
    if (image == null) return;

    setState(() => _isSaving = true);
    try {
      final storageRef = FirebaseStorage.instance.ref('profile_photos/$uid.jpg');
      await storageRef.putFile(File(image.path));
      final downloadUrl = await storageRef.getDownloadURL();
      if (!mounted) return;
      setState(() => _photoUrl = downloadUrl);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profil fotoğrafı güncellenemedi.'),
          backgroundColor: FRColors.danger,
        ),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _saveProfile(UserModel user) async {
    setState(() => _isSaving = true);

    final fullName = _nameController.text.trim();
    final username = _usernameController.text.trim();
    final parts = fullName.split(RegExp(r'\s+')).where((part) => part.isNotEmpty).toList(growable: false);

    final updatedUser = user.copyWith(
      name: fullName,
      firstName: parts.isEmpty ? user.firstName : parts.first,
      lastName: parts.length > 1 ? parts.sublist(1).join(' ') : user.lastName,
      username: username,
      photoUrl: _photoUrl,
    );

    final success = await ref.read(profileProvider.notifier).updateProfile(updatedUser);
    if (!mounted) return;

    setState(() => _isSaving = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(success ? 'Profil kimliğin güncellendi.' : 'Profil kaydedilemedi.'),
        backgroundColor: success ? FRColors.espresso : FRColors.danger,
      ),
    );

    if (success) Navigator.of(context).maybePop();
  }

  @override
  Widget build(BuildContext context) {
    final profileState = ref.watch(profileProvider);

    return Scaffold(
      backgroundColor: FRColors.background,
      appBar: AppBar(
        backgroundColor: FRColors.background,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: FRColors.espresso),
        title: const Text(
          'Dijital Kimlik',
          style: TextStyle(
            color: FRColors.espresso,
            fontSize: 17,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: profileState.when(
        loading: () => const Center(child: CircularProgressIndicator(color: FRColors.espresso)),
        error: (error, _) => Center(child: Text('Bir hata oluştu: $error')),
        data: (user) {
          if (user == null) {
            return const Center(child: Text('Profil bulunamadı.'));
          }

          if (!_didInit) {
            _nameController.text = user.name.trim();
            _usernameController.text = user.username ?? '';
            _photoUrl = user.photoUrl;
            _didInit = true;
          }

          return ListView(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 40),
            children: [
              _SectionHeader(label: 'Kimlik Profili'),
              const SizedBox(height: 12),
              _LuxuryCard(
                child: Column(
                  children: [
                    const SizedBox(height: 4),
                    _AvatarHero(
                      photoUrl: _photoUrl,
                      fallbackName: _nameController.text,
                      onTap: _pickPhoto,
                    ),
                    const SizedBox(height: 18),
                    _LuxuryField(
                      label: 'Ad Soyad',
                      controller: _nameController,
                      readOnly: true,
                      prefix: const Icon(
                        CupertinoIcons.lock_fill,
                        size: 14,
                        color: FRColors.textHint,
                      ),
                      textColor: FRColors.textMutedSoft,
                    ),
                    const SizedBox(height: 14),
                    _LuxuryField(
                      label: 'Kullanıcı Adı',
                      controller: _usernameController,
                      hintText: '@fiyatradar',
                    ),
                    const SizedBox(height: 22),
                    _SaveButton(
                      isBusy: _isSaving,
                      onTap: _isSaving ? null : () => _saveProfile(user),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 22),
              Text(
                _footerText(user),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: FRColors.textMuted,
                  fontSize: 12.5,
                  height: 1.5,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  String _footerText(UserModel user) {
    final createdAt = user.createdAt;
    final months = <int, String>{
      1: 'Ocak',
      2: 'Şubat',
      3: 'Mart',
      4: 'Nisan',
      5: 'Mayıs',
      6: 'Haziran',
      7: 'Temmuz',
      8: 'Ağustos',
      9: 'Eylül',
      10: 'Ekim',
      11: 'Kasım',
      12: 'Aralık',
    };
    final joinText = 'Aramıza Katılma: ${months[createdAt.month] ?? 'Mart'} ${createdAt.year}';
    final role = user.role?.trim().isNotEmpty == true
        ? user.role!.trim()
        : user.isAdmin
            ? 'Kurucu'
            : 'Üye';
    return '$joinText • Yetki: $role';
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        label.toUpperCase(),
        style: const TextStyle(
          color: FRColors.espresso,
          fontSize: 11,
          fontWeight: FontWeight.w800,
          letterSpacing: 1.5,
        ),
      ),
    );
  }
}

class _LuxuryCard extends StatelessWidget {
  const _LuxuryCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: FRColors.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: FRColors.shadowSoft,
            blurRadius: 20,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _AvatarHero extends StatelessWidget {
  const _AvatarHero({
    required this.photoUrl,
    required this.fallbackName,
    required this.onTap,
  });

  final String? photoUrl;
  final String fallbackName;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final initials = fallbackName.trim().isEmpty
        ? 'FR'
        : fallbackName
            .trim()
            .split(RegExp(r'\s+'))
            .take(2)
            .map((part) => part[0].toUpperCase())
            .join();

    return Center(
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: 90,
            height: 90,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [
                  FRColors.camel.withOpacity(0.22),
                  FRColors.espresso.withOpacity(0.10),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              border: Border.all(color: FRColors.camel.withOpacity(0.28)),
              boxShadow: const [
                BoxShadow(
                  color: FRColors.shadowMedium,
                  blurRadius: 22,
                  offset: Offset(0, 12),
                ),
              ],
            ),
            child: ClipOval(
              child: photoUrl == null || photoUrl!.isEmpty
                  ? Center(
                      child: Text(
                        initials,
                        style: const TextStyle(
                          color: FRColors.espresso,
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    )
                  : Image.network(photoUrl!, fit: BoxFit.cover),
            ),
          ),
          Positioned(
            right: -2,
            bottom: -2,
            child: GestureDetector(
              onTap: onTap,
              child: Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: FRColors.espresso,
                  shape: BoxShape.circle,
                  border: Border.all(color: FRColors.surface, width: 2),
                  boxShadow: const [
                    BoxShadow(
                      color: FRColors.shadowMedium,
                      blurRadius: 10,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: const Icon(
                  CupertinoIcons.camera_fill,
                  size: 16,
                  color: FRColors.camel,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LuxuryField extends StatelessWidget {
  const _LuxuryField({
    required this.label,
    required this.controller,
    this.hintText,
    this.readOnly = false,
    this.prefix,
    this.textColor,
  });

  final String label;
  final TextEditingController controller;
  final String? hintText;
  final bool readOnly;
  final Widget? prefix;
  final Color? textColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      decoration: BoxDecoration(
        color: FRColors.backgroundWarm.withOpacity(readOnly ? 0.55 : 0.85),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: readOnly ? FRColors.borderStrong.withOpacity(0.55) : FRColors.borderStrong.withOpacity(0.8),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                label,
                style: const TextStyle(
                  color: FRColors.espresso,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.5,
                ),
              ),
              if (prefix != null) ...[
                const SizedBox(width: 6),
                prefix!,
              ],
            ],
          ),
          const SizedBox(height: 8),
          TextField(
            controller: controller,
            readOnly: readOnly,
            cursorColor: FRColors.camel,
            style: TextStyle(
              color: textColor ?? FRColors.espresso,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
            decoration: InputDecoration(
              isDense: true,
              hintText: hintText,
              hintStyle: const TextStyle(
                color: FRColors.textHint,
                fontWeight: FontWeight.w600,
              ),
              border: InputBorder.none,
            ),
          ),
        ],
      ),
    );
  }
}

class _SaveButton extends StatelessWidget {
  const _SaveButton({required this.isBusy, required this.onTap});

  final bool isBusy;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 180),
        opacity: onTap == null ? 0.72 : 1,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: const LinearGradient(
              colors: [FRColors.espressoSoft, Color(0xFF090603)],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
            boxShadow: const [
              BoxShadow(
                color: FRColors.shadowMedium,
                blurRadius: 18,
                offset: Offset(0, 10),
              ),
            ],
          ),
          child: Center(
            child: isBusy
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: FRColors.camel,
                    ),
                  )
                : const Text(
                    'Profili Kaydet',
                    style: TextStyle(
                      color: FRColors.camel,
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.2,
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}
