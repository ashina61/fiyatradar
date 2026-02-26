import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/product_provider.dart';
import '../../providers/user_provider.dart';
import '../../utils/theme.dart';

Future<void> _showEditUserDialogGlobal(BuildContext context, WidgetRef ref, dynamic user) async {
  final nameController = TextEditingController(text: user.name);
  final roleController = TextEditingController(text: user.isAdmin ? 'admin' : (user.role ?? 'user'));
  final pointsController = TextEditingController(text: user.points.toString());
  final levelController = TextEditingController();
  bool verifiedBadge = user.isAdmin;

  await showDialog<void>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const Text('Üye düzenleme'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameController, decoration: const InputDecoration(labelText: 'displayName')),
            const SizedBox(height: 8),
            TextField(controller: roleController, decoration: const InputDecoration(labelText: 'role (user/admin)')),
            const SizedBox(height: 8),
            TextField(controller: pointsController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'pointsTotal')),
            const SizedBox(height: 8),
            TextField(controller: levelController, decoration: const InputDecoration(labelText: 'level override (opsiyonel)')),
            const SizedBox(height: 8),
            StatefulBuilder(
              builder: (context, setState) => SwitchListTile.adaptive(
                contentPadding: EdgeInsets.zero,
                value: verifiedBadge,
                title: const Text('Verified badge'),
                onChanged: (v) => setState(() => verifiedBadge = v),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Vazgeç')),
        FilledButton(
          onPressed: () async {
            await ref.read(adminUserManagementDomainServiceProvider).updateUserByAdmin(user.uid, {
              'name': nameController.text.trim(),
              'displayName': nameController.text.trim(),
              'role': roleController.text.trim().isEmpty ? 'user' : roleController.text.trim(),
              'isAdmin': roleController.text.trim() == 'admin',
              'pointsTotal': int.tryParse(pointsController.text.trim()) ?? user.points,
              'totalPoints': int.tryParse(pointsController.text.trim()) ?? user.points,
              'verifiedBadge': verifiedBadge,
              'updatedAt': FieldValue.serverTimestamp(),
            });
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Üye güncellendi')));
            }
            if (dialogContext.mounted) Navigator.pop(dialogContext);
          },
          child: const Text('Kaydet'),
        ),
      ],
    ),
  );
}

// ---------------------------------------------------------------------------
// Tab 6: Kullanici Yonetimi
// ---------------------------------------------------------------------------
class AdminUserManagementTab extends ConsumerWidget {
  const AdminUserManagementTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final usersAsync = ref.watch(allUsersProvider);
    final theme = Theme.of(context);

    return usersAsync.when(
      data: (users) {
        if (users.isEmpty) {
          return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(Icons.people_outlined, size: 64, color: theme.hintColor),
            const SizedBox(height: AppSpacing.md),
            Text('Henuz kullanici yok', style: TextStyle(color: theme.hintColor, fontSize: 16)),
          ]));
        }
        return ListView.builder(
          padding: const EdgeInsets.all(AppSpacing.md),
          itemCount: users.length,
          itemBuilder: (context, index) {
            final user = users[index];
            return Card(
              margin: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Row(children: [
                  Container(
                    width: 48, height: 48,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.primary.withOpacity(0.1),
                      image: user.photoUrl != null ? DecorationImage(
                        image: NetworkImage(user.photoUrl!),
                        fit: BoxFit.cover,
                        onError: (_, __) {},
                      ) : null,
                    ),
                    child: user.photoUrl == null ? Center(
                      child: Text(user.name.isNotEmpty ? user.name[0].toUpperCase() : '?',
                        style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary, fontSize: 18)),
                    ) : null,
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Row(children: [
                      Flexible(child: Text(user.name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14), overflow: TextOverflow.ellipsis)),
                      if (user.isAdmin) ...[
                        const SizedBox(width: 4),
                        const Icon(Icons.verified, color: Colors.lightBlueAccent, size: 16),
                      ],
                    ]),
                    const SizedBox(height: 2),
                    Text(user.email, style: TextStyle(fontSize: 12, color: theme.hintColor), overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 4),
                    Row(children: [
                      _AdminInfoChip(icon: Icons.price_change, label: '${user.priceEntries} fiyat'),
                      const SizedBox(width: 4),
                      _AdminInfoChip(icon: Icons.stars, label: '${user.points} puan'),
                      const SizedBox(width: 4),
                      _AdminInfoChip(icon: Icons.verified_outlined, label: '${user.validations} d.'),
                    ]),
                  ])),
                  Column(
                    children: [
                      IconButton(
                        tooltip: 'Üye düzenle',
                        icon: const Icon(Icons.edit_outlined),
                        onPressed: () => _showEditUserDialogGlobal(context, ref, user),
                      ),
                      IconButton(
                        tooltip: user.isBanned ? 'Ban kaldır' : 'Kullanıcıyı banla',
                        icon: Icon(user.isBanned ? Icons.lock_open_rounded : Icons.block_rounded,
                            color: user.isBanned ? Colors.green : Colors.redAccent),
                        onPressed: () async {
                          final adminUid = FirebaseAuth.instance.currentUser?.uid;
                          await ref.read(adminUserManagementDomainServiceProvider).setUserBanStatusByAdmin(
                            userId: user.uid,
                            isBanned: !user.isBanned,
                            reason: user.isBanned ? null : 'Admin panel işlemi',
                            adminUid: adminUid,
                          );
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(user.isBanned ? '${user.name} banı kaldırıldı' : '${user.name} banlandı'),
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          }
                        },
                      ),
                      IconButton(
                        tooltip: 'Üyeliği sil',
                        icon: const Icon(Icons.person_remove_alt_1_rounded, color: Colors.red),
                        onPressed: () async {
                          final confirmed = await showDialog<bool>(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              title: const Text('Üyeliği sil'),
                              content: Text('${user.name} kullanıcısını tamamen silmek istiyor musunuz?'),
                              actions: [
                                TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('İptal')),
                                FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Sil')),
                              ],
                            ),
                          );
                          if (confirmed != true) return;
                          await ref.read(adminUserManagementDomainServiceProvider).deleteUserByAdmin(user.uid);
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('${user.name} silindi'), behavior: SnackBarBehavior.floating),
                            );
                          }
                        },
                      ),
                      Switch(
                        value: user.isAdmin,
                        activeColor: AppColors.primary,
                        onChanged: (val) {
                          ref.read(userNotifierProvider.notifier).toggleUserAdmin(user.uid, val);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(val ? '${user.name} admin yapildi' : '${user.name} admin kaldirildi'),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ]),
              ),
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, __) => const Center(child: Text('Kullanicilar yuklenemedi')),
    );
  }
}

class _AdminInfoChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _AdminInfoChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceVariant,
        borderRadius: BorderRadius.circular(AppRadius.xl),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: theme.hintColor),
          const SizedBox(width: 3),
          Text(label, style: TextStyle(fontSize: 10, color: theme.hintColor)),
        ],
      ),
    );
  }
}
