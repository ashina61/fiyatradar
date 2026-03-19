import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/user_model.dart';
import '../../providers/product_provider.dart';
import '../../providers/user_provider.dart';
import '../../services/domain_services.dart';

const Color pBrandBrown = Color(0xFF6A442A);
const Color pBgApp = Color(0xFFF8F6F4);
const Color pSurface = Color(0xFFFFFFFF);
const Color pStudio = Color(0xFFEBE5DF);
const Color pGoldLight = Color(0x33C29B78);
const Color pDarkHeader = Color(0xFF1A110D);
const Color pTextMain = Color(0xFF211510);
const Color pTextMuted = Color(0xFF8C7B70);
const Color pAlert = Color(0xFFFF3B30);
const Color pAlertLight = Color(0x1AFF3B30);
const Color pSuccess = Color(0xFF34C759);
const Color pBorder = Color(0x1F6A442A);

class AdminUserManagementTab extends ConsumerWidget {
  const AdminUserManagementTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final usersAsync = ref.watch(allUsersProvider);

    return Container(
      color: pBgApp,
      child: usersAsync.when(
        loading: () => const Center(child: CircularProgressIndicator(color: pBrandBrown)),
        error: (err, stack) => Center(child: Text('Hata: $err', style: const TextStyle(color: pAlert))),
        data: (users) {
          if (users.isEmpty) {
            return const Center(child: Text('Henüz kullanıcı yok.', style: TextStyle(color: pTextMuted, fontWeight: FontWeight.w600)));
          }
          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 100),
            itemCount: users.length,
            itemBuilder: (context, index) => _PremiumUserCard(user: users[index]),
          );
        },
      ),
    );
  }
}

class _PremiumUserCard extends ConsumerStatefulWidget {
  const _PremiumUserCard({required this.user});

  final UserModel user;

  @override
  ConsumerState<_PremiumUserCard> createState() => _PremiumUserCardState();
}

class _PremiumUserCardState extends ConsumerState<_PremiumUserCard> {
  bool _isExpanded = false;
  bool _isProcessing = false;

  @override
  Widget build(BuildContext context) {
    final user = widget.user;
    final isBanned = user.isBanned;
    final isAdmin = user.isAdmin;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: pSurface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isBanned ? pAlert.withOpacity(0.3) : pBorder),
        boxShadow: const [BoxShadow(color: Color(0x0A6A442A), blurRadius: 15, offset: Offset(0, 4))],
      ),
      child: Opacity(
        opacity: isBanned ? 0.7 : 1.0,
        child: Column(
          children: [
            InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: () => setState(() => _isExpanded = !_isExpanded),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    _buildAvatar(user, isAdmin, isBanned),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text((user.username.isNotEmpty ? user.username : user.name).toString(), style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: isBanned ? pAlert : pTextMain), maxLines: 1, overflow: TextOverflow.ellipsis),
                          Text(user.email, style: const TextStyle(fontSize: 12, color: pTextMuted), maxLines: 1, overflow: TextOverflow.ellipsis),
                          const SizedBox(height: 6),
                          _buildStats(user),
                        ],
                      ),
                    ),
                    if (_isProcessing) const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: pBrandBrown)) else Icon(_isExpanded ? Icons.expand_less : Icons.expand_more, color: pBrandBrown),
                  ],
                ),
              ),
            ),
            if (_isExpanded) _buildActionBar(context, user, isBanned, isAdmin),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatar(UserModel user, bool isAdmin, bool isBanned) {
    final displaySeed = user.username.isNotEmpty ? user.username : user.name;
    return Stack(
      children: [
        Container(
          width: 50, height: 50,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isBanned ? pAlertLight : (isAdmin ? pGoldLight : pStudio),
            image: user.photoUrl != null ? DecorationImage(image: NetworkImage(user.photoUrl!), fit: BoxFit.cover) : null,
          ),
          alignment: Alignment.center,
          child: user.photoUrl == null ? Text(displaySeed.isNotEmpty ? displaySeed[0].toUpperCase() : '?', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: isBanned ? pAlert : (isAdmin ? pDarkHeader : pTextMuted))) : null,
        ),
        if (isAdmin) const Positioned(bottom: 0, right: 0, child: Icon(Icons.verified, color: Colors.blue, size: 16)),
      ],
    );
  }

  Widget _buildStats(UserModel user) {
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: [
        _miniPill(Icons.stars, '${user.points} Puan'),
        _miniPill(Icons.price_change, '${user.priceEntries} Fiyat'),
        if (user.name.trim().isNotEmpty) _miniPill(Icons.badge_outlined, user.name.trim()),
      ],
    );
  }

  Widget _miniPill(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(color: pStudio, borderRadius: BorderRadius.circular(4)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [Icon(icon, size: 10, color: pBrandBrown), const SizedBox(width: 4), Text(text, style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: pTextMain))]),
    );
  }

  Widget _buildActionBar(BuildContext context, UserModel user, bool isBanned, bool isAdmin) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: const BoxDecoration(color: pBgApp, borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)), border: Border(top: BorderSide(color: pBorder))),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _actionBtn(Icons.edit, 'Düzenle', pBrandBrown, _isProcessing ? null : () => _showEditUserBottomSheet(context, ref, user)),
          _actionBtn(isBanned ? Icons.lock_open : Icons.block, isBanned ? 'Aç' : 'Banla', isBanned ? pSuccess : pAlert, _isProcessing ? null : () => _handleBanToggle(user, isBanned)),
          _actionBtn(Icons.person_remove, 'Sil', pAlert, _isProcessing ? null : () => _handleDelete(user)),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Switch.adaptive(
                value: isAdmin,
                activeColor: pBrandBrown,
                onChanged: _isProcessing ? null : (val) async {
                  await _runAction(
                    successMessage: val ? 'Kullanıcı admin yapıldı.' : 'Admin yetkisi kaldırıldı.',
                    action: () => ref.read(userNotifierProvider.notifier).toggleUserAdmin(user.uid, val),
                  );
                },
              ),
              const Text('ADMIN', style: TextStyle(fontSize: 8, fontWeight: FontWeight.bold)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _actionBtn(IconData icon, String label, Color col, VoidCallback? onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Opacity(
        opacity: onTap == null ? 0.5 : 1,
        child: Column(children: [Icon(icon, color: col, size: 20), const SizedBox(height: 4), Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold))]),
      ),
    );
  }

  Future<void> _handleBanToggle(UserModel user, bool isBanned) async {
    final adminUid = FirebaseAuth.instance.currentUser?.uid;
    await _runAction(
      successMessage: isBanned ? 'Kullanıcının banı kaldırıldı.' : 'Kullanıcı banlandı.',
      action: () => ref.read(adminUserManagementDomainServiceProvider).setUserBanStatusByAdmin(
        userId: user.uid,
        isBanned: !isBanned,
        adminUid: adminUid,
      ),
    );
  }

  Future<void> _handleDelete(UserModel user) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Kullanıcıyı pasifleştir'),
        content: Text('${user.username.isNotEmpty ? user.username : user.name} için hesap erişimi kapatılsın mı?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Vazgeç')),
          FilledButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Sil')),
        ],
      ),
    );
    if (confirmed != true) return;

    await _runAction(
      successMessage: 'Kullanıcı pasife alındı.',
      action: () => ref.read(adminUserManagementDomainServiceProvider).deleteUserByAdmin(user.uid),
    );
  }

  Future<void> _runAction({required Future<void> Function() action, required String successMessage}) async {
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _isProcessing = true);
    try {
      await action();
      if (!mounted) return;
      messenger.showSnackBar(SnackBar(content: Text(successMessage), behavior: SnackBarBehavior.floating));
    } catch (error) {
      if (!mounted) return;
      messenger.showSnackBar(SnackBar(content: Text('İşlem başarısız: $error'), behavior: SnackBarBehavior.floating, backgroundColor: pAlert));
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }
}

Future<void> _showEditUserBottomSheet(BuildContext context, WidgetRef ref, UserModel user) async {
  final usernameController = TextEditingController(text: user.username);
  final nameController = TextEditingController(text: user.name);
  var saving = false;

  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setModalState) {
          Future<void> submit() async {
            setModalState(() => saving = true);
            try {
              final nextName = nameController.text.trim();
              final nextUsername = usernameController.text.trim().toLowerCase();
              if (nextName.isEmpty || nextUsername.isEmpty) {
                throw Exception('Ad soyad ve kullanıcı adı boş bırakılamaz.');
              }
              await ref.read(adminUserManagementDomainServiceProvider).updateUserByAdmin(user.uid, {
                'username': nextUsername,
                'name': nextName,
                'displayName': nextName,
                'updatedAt': FieldValue.serverTimestamp(),
              });
              if (!context.mounted) return;
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Kullanıcı bilgileri güncellendi.'), behavior: SnackBarBehavior.floating));
            } catch (error) {
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Düzenleme başarısız: $error'), behavior: SnackBarBehavior.floating, backgroundColor: pAlert));
            } finally {
              if (context.mounted) setModalState(() => saving = false);
            }
          }

          return Padding(
            padding: EdgeInsets.only(left: 20, right: 20, top: 20, bottom: MediaQuery.of(context).viewInsets.bottom + 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Kullanıcı Düzenle', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: pTextMain)),
                const SizedBox(height: 16),
                TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Ad Soyad')),
                const SizedBox(height: 12),
                TextField(controller: usernameController, decoration: const InputDecoration(labelText: 'Kullanıcı Adı')),
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: saving ? null : submit,
                    child: saving ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Text('Kaydet'),
                  ),
                ),
              ],
            ),
          );
        },
      );
    },
  );
}
