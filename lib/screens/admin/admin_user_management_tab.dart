import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/user_model.dart'; // Yolunu kendi projene göre kontrol et
import '../../providers/product_provider.dart';
import '../../providers/user_provider.dart';
import '../../utils/elite_level_engine.dart';
import '../../utils/theme.dart';

// --- PREMIUM RENK PALETİ ---
const Color pBrandBrown = Color(0xFF6A442A);
const Color pBrandBrownLight = Color(0x266A442A);
const Color pBgApp = Color(0xFFF8F6F4);
const Color pSurface = Color(0xFFFFFFFF);
const Color pStudio = Color(0xFFEBE5DF);
const Color pGold = Color(0xFFC29B78);
const Color pGoldLight = Color(0x33C29B78);

// EKSİK OLAN SATIR TAM OLARAK BU AŞAĞIDAKİ:
const Color pDarkHeader = Color(0xFF1A110D); 

const Color pTextMain = Color(0xFF211510);
const Color pTextMuted = Color(0xFF8C7B70);
const Color pAlert = Color(0xFFFF3B30);
const Color pAlertLight = Color(0x1AFF3B30);
const Color pSuccess = Color(0xFF34C759);
const Color pBorder = Color(0x1F6A442A);


// ---------------------------------------------------------------------------
// Tab 6: Kullanıcı Yönetimi
// ---------------------------------------------------------------------------
class AdminUserManagementTab extends ConsumerWidget {
  const AdminUserManagementTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final usersAsync = ref.watch(allUsersProvider);

    return Container(
      color: pBgApp,
      child: usersAsync.when(
        data: (users) {
          if (users.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.people_outline, size: 64, color: pTextMuted),
                  SizedBox(height: 16),
                  Text('Henüz kullanıcı yok', style: TextStyle(color: pTextMuted, fontSize: 16, fontWeight: FontWeight.w600)),
                ],
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 100),
            itemCount: users.length,
            itemBuilder: (context, index) {
              final user = users[index];
              return _PremiumUserCard(user: user);
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator(color: pBrandBrown)),
        error: (_, __) => const Center(child: Text('Kullanıcılar yüklenemedi', style: TextStyle(color: pAlert))),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// PREMIUM KULLANICI KARTI (Açılır Kapanır)
// ---------------------------------------------------------------------------
class _PremiumUserCard extends ConsumerStatefulWidget {
  final dynamic user; // UserModel olduğunu varsayıyoruz
  const _PremiumUserCard({required this.user});

  @override
  ConsumerState<_PremiumUserCard> createState() => _PremiumUserCardState();
}

class _PremiumUserCardState extends ConsumerState<_PremiumUserCard> {
  bool _isExpanded = false;

  void _toggleExpand() {
    setState(() {
      _isExpanded = !_isExpanded;
    });
  }

  @override
  Widget build(BuildContext context) {
    final user = widget.user;
    final isBanned = user.isBanned == true;
    final isAdmin = user.isAdmin == true;

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
            // KART ÜST KISIM (Sabit)
            InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: _toggleExpand,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    // Avatar
                    Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Container(
                          width: 50, height: 50,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isBanned ? pAlertLight : (isAdmin ? pGoldLight : pStudio),
                            image: user.photoUrl != null
                                ? DecorationImage(image: NetworkImage(user.photoUrl!), fit: BoxFit.cover)
                                : null,
                          ),
                          alignment: Alignment.center,
                          child: user.photoUrl == null
                              ? Text(
                                  user.name.isNotEmpty ? user.name[0].toUpperCase() : '?',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w900,
                                    color: isBanned ? pAlert : (isAdmin ? pDarkHeader : pTextMuted),
                                  ),
                                )
                              : null,
                        ),
                        if (isAdmin || user.verifiedBadge == true)
                          Positioned(
                            bottom: -2, right: -2,
                            child: Container(
                              padding: const EdgeInsets.all(2),
                              decoration: const BoxDecoration(color: pSurface, shape: BoxShape.circle),
                              child: const Icon(Icons.verified, color: Colors.blueAccent, size: 16),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(width: 16),
                    
                    // Kullanıcı Bilgileri
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  user.name,
                                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: isBanned ? pAlert : pTextMain, letterSpacing: 0.5),
                                  maxLines: 1, overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (isBanned) ...[
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(color: pAlert, borderRadius: BorderRadius.circular(4)),
                                  child: const Text('BANLI', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: pSurface)),
                                ),
                              ]
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(user.email ?? '', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: pTextMuted), maxLines: 1, overflow: TextOverflow.ellipsis),
                          const SizedBox(height: 6),
                          
                          // İstatistik Hapları
                          Wrap(
                            spacing: 6, runSpacing: 6,
                            children: [
                              _StatPill(icon: Icons.stars, label: '${user.points ?? 0} Puan'),
                              _StatPill(icon: Icons.price_change, label: '${user.priceEntries ?? 0} Fiyat'),
                              if ((user.validations ?? 0) > 0)
                                _StatPill(icon: Icons.verified_user, label: '${user.validations} Doğr.'),
                            ],
                          ),
                        ],
                      ),
                    ),
                    
                    // Genişletme Oku
                    AnimatedRotation(
                      turns: _isExpanded ? 0.5 : 0.0,
                      duration: const Duration(milliseconds: 300),
                      child: Container(
                        width: 36, height: 36,
                        decoration: BoxDecoration(color: pBgApp, borderRadius: BorderRadius.circular(10)),
                        child: const Icon(Icons.expand_more, color: pBrandBrown, size: 20),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            // GİZLİ AKSİYON BARI (Alt Kısım)
            AnimatedSize(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              child: !_isExpanded
                  ? const SizedBox.shrink()
                  : Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: const BoxDecoration(
                        color: pBgApp,
                        borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
                        border: Border(top: BorderSide(color: pBorder)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          // Düzenle Butonu
                          _ActionBtn(
                            icon: Icons.edit,
                            label: 'Düzenle',
                            color: pBrandBrown,
                            onTap: () => _showEditUserBottomSheet(context, ref, user),
                          ),
                          // Banla / Ban Kaldır Butonu
                          _ActionBtn(
                            icon: isBanned ? Icons.lock_open : Icons.block,
                            label: isBanned ? 'Ban Kaldır' : 'Banla',
                            color: isBanned ? pSuccess : pAlert,
                            onTap: () async {
                              final adminUid = FirebaseAuth.instance.currentUser?.uid;
                              await ref.read(adminUserManagementDomainServiceProvider).setUserBanStatusByAdmin(
                                userId: user.uid,
                                isBanned: !isBanned,
                                reason: isBanned ? null : 'Admin panel işlemi',
                                adminUid: adminUid,
                              );
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(isBanned ? '${user.name} banı kaldırıldı' : '${user.name} banlandı'), backgroundColor: isBanned ? pSuccess : pAlert));
                              }
                            },
                          ),
                          // Sil Butonu
                          _ActionBtn(
                            icon: Icons.person_remove,
                            label: 'Sil',
                            color: pAlert,
                            onTap: () async {
                              final confirmed = await showDialog<bool>(
                                context: context,
                                builder: (ctx) => AlertDialog(
                                  title: const Text('Üyeliği Sil'),
                                  content: Text('${user.name} kullanıcısını tamamen silmek istiyor musunuz?'),
                                  actions: [
                                    TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('İptal')),
                                    FilledButton(style: FilledButton.styleFrom(backgroundColor: pAlert), onPressed: () => Navigator.pop(ctx, true), child: const Text('Sil')),
                                  ],
                                ),
                              );
                              if (confirmed != true) return;
                              await ref.read(adminUserManagementDomainServiceProvider).deleteUserByAdmin(user.uid);
                              if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${user.name} silindi'), backgroundColor: pBrandBrown));
                            },
                          ),
                          // Admin Yap / Kaldır (Switchli Özel Buton)
                          Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Transform.scale(
                                scale: 0.8,
                                child: Switch.adaptive(
                                  value: isAdmin,
                                  activeColor: pSurface,
                                  activeTrackColor: pBrandBrown,
                                  inactiveThumbColor: pSurface,
                                  inactiveTrackColor: pStudio,
                                  onChanged: (val) {
                                    ref.read(userNotifierProvider.notifier).toggleUserAdmin(user.uid, val);
                                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(val ? '${user.name} admin yapıldı' : '${user.name} adminliği alındı'), backgroundColor: pBrandBrown));
                                  },
                                ),
                              ),
                              const Text('Admin', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: pTextMain)),
                            ],
                          ),
                        ],
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// LÜKS BOTTOM SHEET (Eski Dialog Yerine)
// ---------------------------------------------------------------------------
Future<void> _showEditUserBottomSheet(BuildContext context, WidgetRef ref, dynamic user) async {
  final nameController = TextEditingController(text: user.name);
  final roleController = TextEditingController(text: user.isAdmin ? 'admin' : (user.role ?? 'user'));
  final pointsController = TextEditingController(text: user.points.toString());
  final levelController = TextEditingController();
  bool verifiedBadge = user.verifiedBadge == true;

  await showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setState) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: Container(
          decoration: const BoxDecoration(color: pBgApp, borderRadius: BorderRadius.vertical(top: Radius.circular(32))),
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(width: 40, height: 4, decoration: BoxDecoration(color: pBorder, borderRadius: BorderRadius.circular(10))),
                const SizedBox(height: 20),
                const Text('Üye Düzenle', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: pTextMain)),
                const SizedBox(height: 24),

                _PremiumIconInput(icon: Icons.person, hint: 'Kullanıcı Adı', controller: nameController),
                const SizedBox(height: 12),
                _PremiumIconInput(icon: Icons.admin_panel_settings, hint: 'Rol (user/admin)', controller: roleController),
                const SizedBox(height: 12),
                _PremiumIconInput(icon: Icons.stars, hint: 'Toplam Puan', controller: pointsController, keyboardType: TextInputType.number),
                const SizedBox(height: 12),
                _PremiumIconInput(icon: Icons.military_tech, hint: 'Level Override (Opsiyonel)', controller: levelController),
                const SizedBox(height: 16),

                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(color: pSurface, borderRadius: BorderRadius.circular(16), border: Border.all(color: pBorder)),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.verified, color: Colors.blueAccent, size: 20),
                          SizedBox(width: 8),
                          Text('Doğrulanmış Rozet', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: pTextMain)),
                        ],
                      ),
                      Switch.adaptive(
                        value: verifiedBadge,
                        activeColor: pSurface,
                        activeTrackColor: Colors.blueAccent, // Mavi tik uyumu
                        inactiveThumbColor: pSurface,
                        inactiveTrackColor: pStudio,
                        onChanged: (value) => setState(() => verifiedBadge = value),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                GestureDetector(
                  onTap: () async {
                    final updatedPoints = int.tryParse(pointsController.text.trim()) ?? user.points;
                    final levelOverride = levelController.text.trim();
                    final computedLevelName = EliteLevelEngine.getLevelStyle(
                      EliteLevelEngine.getPointsLevel(updatedPoints),
                    ).label;

                    await ref.read(adminUserManagementDomainServiceProvider).updateUserByAdmin(user.uid, {
                      'name': nameController.text.trim(),
                      'displayName': nameController.text.trim(),
                      'role': roleController.text.trim().isEmpty ? 'user' : roleController.text.trim(),
                      'isAdmin': roleController.text.trim() == 'admin',
                      'points': updatedPoints,
                      'pointsTotal': updatedPoints,
                      'totalPoints': updatedPoints,
                      'level': levelOverride.isNotEmpty ? levelOverride : computedLevelName,
                      'levelName': levelOverride.isNotEmpty ? levelOverride : computedLevelName,
                      'verifiedBadge': verifiedBadge,
                      'updatedAt': FieldValue.serverTimestamp(),
                    });
                    
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Üye başarıyla güncellendi', style: TextStyle(color: pSurface)), backgroundColor: pBrandBrown));
                    }
                    if (ctx.mounted) Navigator.pop(ctx);
                  },
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    decoration: BoxDecoration(color: pBrandBrown, borderRadius: BorderRadius.circular(100), boxShadow: const [BoxShadow(color: Color(0x666A442A), blurRadius: 20, offset: Offset(0, 8))]),
                    alignment: Alignment.center,
                    child: const Text('Kaydet', style: TextStyle(color: pSurface, fontSize: 16, fontWeight: FontWeight.w800, letterSpacing: 0.5)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

// --- YARDIMCI WIDGETLAR ---

class _StatPill extends StatelessWidget {
  final IconData icon;
  final String label;
  const _StatPill({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: pStudio, borderRadius: BorderRadius.circular(100)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: pBrandBrown),
          const SizedBox(width: 4),
          Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: pTextMain)),
        ],
      ),
    );
  }
}

class _ActionBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ActionBtn({required this.icon, required this.label, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: pSurface, borderRadius: BorderRadius.circular(12), boxShadow: const [BoxShadow(color: Color(0x0A000000), blurRadius: 8, offset: Offset(0, 2))]),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 6),
          Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: pTextMain)),
        ],
      ),
    );
  }
}

class _PremiumIconInput extends StatelessWidget {
  final IconData icon;
  final String hint;
  final TextEditingController controller;
  final TextInputType? keyboardType;

  const _PremiumIconInput({required this.icon, required this.hint, required this.controller, this.keyboardType});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(color: pSurface, borderRadius: BorderRadius.circular(16), border: Border.all(color: pBorder)),
      child: Row(
        children: [
          Icon(icon, color: pTextMuted, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              controller: controller,
              keyboardType: keyboardType,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: pTextMain),
              decoration: InputDecoration(
                border: InputBorder.none,
                hintText: hint,
                hintStyle: const TextStyle(color: pTextMuted, fontWeight: FontWeight.w500),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
