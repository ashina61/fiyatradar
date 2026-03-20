import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../models/user_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/profile_provider.dart';
import '../../services/auth_service.dart';
import '../../theme/fr_colors.dart';

class PersonalInfoScreen extends ConsumerStatefulWidget {
  const PersonalInfoScreen({super.key});

  @override
  ConsumerState<PersonalInfoScreen> createState() => _PersonalInfoScreenState();
}

class _PersonalInfoScreenState extends ConsumerState<PersonalInfoScreen> {
  static const List<String> _badWords = [
    'admin',
    'fiyatradar',
    'kurucu',
    'küfür1',
    'küfür2',
  ];

  final _nameController = TextEditingController();
  final _usernameController = TextEditingController();
  bool _isSaving = false;
  File? _selectedPhotoFile;
  String? _photoUrl;
  String? _syncedUserId;
  String? _syncedName;
  String? _syncedUsername;
  String? _syncedPhotoUrl;
  ProviderSubscription<AsyncValue<UserModel?>>? _userModelSubscription;

  @override
  void initState() {
    super.initState();
    _userModelSubscription = ref.listenManual<AsyncValue<UserModel?>>(userModelStreamProvider, (previous, next) {
      next.whenData((user) {
        if (user == null) {
          _clearControllers();
          return;
        }
        _syncControllers(user);
      });
    }, fireImmediately: true);
  }

  @override
  void dispose() {
    _userModelSubscription?.close();
    _nameController.dispose();
    _usernameController.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto() async {
    final image = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
      maxWidth: 1400,
    );
    if (image == null) return;

    if (!mounted) return;
    setState(() {
      _selectedPhotoFile = File(image.path);
    });
  }

  Future<String?> _uploadSelectedPhoto(String uid) async {
    if (_selectedPhotoFile == null) return null;

    final storageRef = FirebaseStorage.instance.ref('profile_photos/$uid.jpg');
    await storageRef.putFile(_selectedPhotoFile!);
    return storageRef.getDownloadURL();
  }

  Future<void> _saveProfile(UserModel user) async {
    final messenger = ScaffoldMessenger.of(context);
    final username = _usernameController.text.trim().toLowerCase();
    final lockedName = _nameController.text.trim();
    final currentUsername = user.username.trim().toLowerCase();
    final isUsernameChanged = username != currentUsername;

    if (lockedName.isEmpty) {
      messenger.showSnackBar(
        _feedbackBar(
          'Ad Soyad alanı boş olamaz.',
          isError: true,
        ),
      );
      return;
    }

    if (isUsernameChanged && username.isEmpty) {
      messenger.showSnackBar(
        _feedbackBar(
          'Lütfen geçerli bir kullanıcı adı girin.',
          isError: true,
        ),
      );
      return;
    }

    if (isUsernameChanged && _containsBadWord(username)) {
      messenger.showSnackBar(
        _feedbackBar(
          'Yasaklı kelime içerdiği için bu kullanıcı adı kabul edilemez.',
          isError: true,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final authService = ref.read(authServiceProvider);
      final firestore = FirebaseFirestore.instance;
      final userRef = firestore.collection('users').doc(user.uid);
      final Map<String, dynamic> updateData = {};
      final now = DateTime.now();
      final lastChangeDate = user.lastUsernameChange?.toDate();
      Timestamp? usernameTimestamp;

      if (_selectedPhotoFile != null) {
        final uploadedPhotoUrl = await _uploadSelectedPhoto(user.uid);
        if (uploadedPhotoUrl != null) {
          updateData['photoUrl'] = uploadedPhotoUrl;
        }
      }

      if (lockedName != user.name.trim()) {
        updateData['name'] = lockedName;
      }

      if (isUsernameChanged) {
        if (lastChangeDate != null) {
          final nextChangeDate = lastChangeDate.add(const Duration(days: 90));
          if (now.isBefore(nextChangeDate)) {
            final remainingDays = nextChangeDate.difference(now).inDays + 1;
            if (!mounted) return;
            setState(() => _isSaving = false);
            messenger.showSnackBar(
              _feedbackBar(
                'Kullanıcı adınızı 3 ayda bir değiştirebilirsiniz. Kalan süre: $remainingDays gün.',
                isError: true,
              ),
            );
            return;
          }
        }

        await authService.ensureUsernameAvailable(username);
        usernameTimestamp = Timestamp.now();
        updateData['username'] = username;
        updateData['displayName'] = username;
        updateData['lastUsernameChange'] = usernameTimestamp;
      }

      if (updateData.isEmpty) {
        if (!mounted) return;
        setState(() => _isSaving = false);
        messenger.showSnackBar(
          _feedbackBar('Kaydedilecek bir değişiklik bulunamadı.', isError: false),
        );
        return;
      }

      if (isUsernameChanged) {
        final batch = firestore.batch();
        batch.update(userRef, updateData);
        batch.set(firestore.collection('usernames').doc(username), {
          'uid': user.uid,
          'username': username,
          'createdAt': FieldValue.serverTimestamp(),
          'lastUsernameChange': usernameTimestamp,
        });

        if (currentUsername.isNotEmpty) {
          batch.delete(firestore.collection('usernames').doc(currentUsername));
        }

        await batch.commit();
      } else {
        await userRef.update(updateData);
      }

      await ref.read(profileProvider.notifier).loadProfile(uid: user.uid);
      await ref.read(authNotifierProvider.notifier).refreshCurrentUser();
      if (!mounted) return;

      setState(() {
        _isSaving = false;
        _selectedPhotoFile = null;
        _photoUrl = (updateData['photoUrl'] as String?) ?? _photoUrl;
      });
      messenger.showSnackBar(
        _feedbackBar(
          'Profiliniz güncellendi.',
          isError: false,
        ),
      );

      Navigator.of(context).maybePop();
    } on FirebaseAuthException catch (error) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      messenger.showSnackBar(
        _feedbackBar(AuthService.mapAuthError(error), isError: true),
      );
    } catch (_) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      messenger.showSnackBar(
        _feedbackBar(
          'Profil güncellenemedi. Lütfen tekrar deneyin.',
          isError: true,
        ),
      );
    }
  }

  bool _containsBadWord(String username) {
    final normalized = username.trim().toLowerCase();
    return _badWords.any((keyword) => normalized.contains(keyword));
  }

  String _referralCode(UserModel user) {
    final firestoreCode = user.inviteCode?.trim() ?? '';
    if (firestoreCode.isNotEmpty) return firestoreCode.toUpperCase();

    final base = user.username.trim().isNotEmpty
        ? user.username.trim()
        : user.uid.substring(0, user.uid.length >= 8 ? 8 : user.uid.length);
    final normalized = base
        .toUpperCase()
        .replaceAll(RegExp(r'[^A-Z0-9]'), '');
    return 'FR-${normalized.isEmpty ? user.uid.substring(0, 6).toUpperCase() : normalized}';
  }

  Future<void> _copyReferralCode(UserModel user) async {
    final code = _referralCode(user);
    await Clipboard.setData(ClipboardData(text: code));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      _feedbackBar(
        'Davet kodun kopyalandı! Arkadaşlarınla paylaşarak puan kazanabilirsin.',
        isError: false,
      ),
    );
  }

  SnackBar _feedbackBar(String message, {required bool isError}) {
    return SnackBar(
      content: Text(message),
      backgroundColor: isError ? FRColors.danger : FRColors.espresso,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    );
  }

  void _clearControllers() {
    _syncedUserId = null;
    _syncedName = null;
    _syncedUsername = null;
    _syncedPhotoUrl = null;
    _selectedPhotoFile = null;
    _photoUrl = null;
    _nameController.clear();
    _usernameController.clear();
    if (mounted) setState(() {});
  }

  void _syncControllers(UserModel user) {
    final nextName = user.name.trim().isNotEmpty
        ? user.name.trim()
        : (user.displayName ?? '').trim();
    final nextUsername = user.username.trim();
    final nextPhotoUrl = user.photoUrl;
    final shouldSync = _syncedUserId != user.uid || _syncedName != nextName || _syncedUsername != nextUsername || _syncedPhotoUrl != nextPhotoUrl;
    if (!shouldSync) return;

    _syncedUserId = user.uid;
    _syncedName = nextName;
    _syncedUsername = nextUsername;
    _syncedPhotoUrl = nextPhotoUrl;

    _nameController.value = _nameController.value.copyWith(
      text: nextName,
      selection: TextSelection.collapsed(offset: nextName.length),
      composing: TextRange.empty,
    );
    _usernameController.value = _usernameController.value.copyWith(
      text: nextUsername,
      selection: TextSelection.collapsed(offset: nextUsername.length),
      composing: TextRange.empty,
    );

    if (_selectedPhotoFile != null) return;

    if (_photoUrl != nextPhotoUrl && mounted) {
      setState(() => _photoUrl = nextPhotoUrl);
      return;
    }
    _photoUrl = nextPhotoUrl;
  }

  @override
  Widget build(BuildContext context) {
    final profileState = ref.watch(userModelStreamProvider);

    return Scaffold(
      backgroundColor: FRColors.bgApp,
      appBar: AppBar(
        backgroundColor: FRColors.bgApp,
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
        loading: () => const Center(child: CircularProgressIndicator(color: FRColors.camel)),
        error: (error, _) => Center(child: Text('Bir hata oluştu: $error')),
        data: (user) {
          if (user == null) {
            return const Center(child: Text('Profil bulunamadı.'));
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
                      localPhotoPath: _selectedPhotoFile?.path,
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
                        color: Color(0xFF9E9E9E),
                      ),
                      textColor: Colors.grey.shade400,
                    ),
                    const SizedBox(height: 14),
                    _LuxuryField(
                      label: 'Kullanıcı Adı',
                      controller: _usernameController,
                      hintText: '@fiyatradar',
                    ),
                    const SizedBox(height: 10),
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: 4),
                        child: Text(
                          'Kullanıcı adınız 3 ayda bir değiştirilebilir.',
                          style: TextStyle(
                            color: FRColors.textMuted,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 22),
                    _SaveButton(
                      isBusy: _isSaving,
                      onTap: _isSaving ? null : () => _saveProfile(user),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              _SectionHeader(label: 'Büyüme Motoru'),
              const SizedBox(height: 12),
              _LuxuryCard(
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Row(
                    children: [
                      Container(
                        width: 46,
                        height: 46,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          gradient: const LinearGradient(
                            colors: [FRColors.goldGlowSoft, FRColors.camelStrong],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: FRColors.camel.withOpacity(0.22),
                              blurRadius: 18,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: const Icon(
                          CupertinoIcons.gift_fill,
                          color: FRColors.espresso,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Davet Kodum',
                              style: TextStyle(
                                color: FRColors.espresso,
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _referralCode(user),
                              style: const TextStyle(
                                color: FRColors.textMuted,
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                      TextButton.icon(
                        onPressed: () => _copyReferralCode(user),
                        style: TextButton.styleFrom(
                          foregroundColor: FRColors.espresso,
                          backgroundColor: FRColors.goldGlowSoft.withOpacity(.18),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 10,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                            side: BorderSide(
                              color: FRColors.camelStrong.withOpacity(.35),
                            ),
                          ),
                        ),
                        icon: const Icon(
                          Icons.copy_rounded,
                          size: 16,
                          color: FRColors.camelDeep,
                        ),
                        label: const Text(
                          'Kopyala',
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            color: FRColors.camelDeep,
                          ),
                        ),
                      ),
                    ],
                  ),
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
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(
            color: FRColors.shadowSoft,
            blurRadius: 24,
            spreadRadius: 1,
            offset: Offset(0, 12),
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
    required this.localPhotoPath,
    required this.fallbackName,
    required this.onTap,
  });

  final String? photoUrl;
  final String? localPhotoPath;
  final String fallbackName;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final parts = fallbackName.trim().split(RegExp(r'\s+')).where((part) => part.isNotEmpty).toList();
    final initials = parts.isEmpty
        ? 'FR'
        : parts.take(2).map((part) => part.substring(0, 1).toUpperCase()).join();

    return Center(
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: 96,
            height: 96,
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
              child: localPhotoPath != null && localPhotoPath!.isNotEmpty
                  ? Image.file(File(localPhotoPath!), fit: BoxFit.cover)
                  : photoUrl == null || photoUrl!.isEmpty
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
        color: readOnly ? Colors.grey.shade100 : FRColors.backgroundWarm.withOpacity(0.85),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: readOnly ? Colors.grey.shade300 : FRColors.borderStrong.withOpacity(0.8),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                label,
                style: TextStyle(
                  color: readOnly ? Colors.grey.shade400 : FRColors.espresso,
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
