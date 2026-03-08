import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// --- PROJE YOLLARINI KONTROL ET ---
import '../../providers/product_provider.dart';
import '../../providers/user_provider.dart';
import '../../utils/elite_level_engine.dart';
import '../../utils/theme.dart';

// --- PREMIUM RENK PALETİ (TÜMÜ BURADA TANIMLI) ---
const Color pBrandBrown = Color(0xFF6A442A);
const Color pBrandBrownLight = Color(0x266A442A); 
const Color pBgApp = Color(0xFFF8F6F4);
const Color pSurface = Color(0xFFFFFFFF);
const Color pStudio = Color(0xFFEBE5DF);
const Color pGold = Color(0xFFC29B78);
const Color pGoldLight = Color(0x33C29B78);
const Color pDarkHeader = Color(0xFF1A110D); // Hataya sebep olan eksik renk buydu
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
            return const Center(
              child: Text('Henüz kullanıcı yok.', style: TextStyle(color: pTextMuted, fontWeight: FontWeight.w600)),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 100),
            itemCount: users.length,
            itemBuilder: (context, index) {
              return _PremiumUserCard(user: users[index]);
            },
          );
        },
      ),
    );
  }
}

class _PremiumUserCard extends ConsumerStatefulWidget {
  final dynamic user;
  const _PremiumUserCard({required this.user});

  @override
  ConsumerState<_PremiumUserCard> createState() => _PremiumUserCardState();
}

class _PremiumUserCardState extends ConsumerState<_PremiumUserCard> {
  bool _isExpanded = false;

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
            // KART ÜST KISIM
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
                          Text(user.name, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: isBanned ? pAlert : pTextMain), maxLines: 1, overflow: TextOverflow.ellipsis),
                          Text(user.email ?? '', style: const TextStyle(fontSize: 12, color: pTextMuted), maxLines: 1, overflow: TextOverflow.ellipsis),
                          const SizedBox(height: 6),
                          _buildStats(user),
                        ],
                      ),
                    ),
                    Icon(_isExpanded ? Icons.expand_less : Icons.expand_more, color: pBrandBrown),
                  ],
                ),
              ),
            ),
            
            // GİZLİ AKSİYON BARI
            if (_isExpanded) _buildActionBar(context, user, isBanned, isAdmin),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatar(dynamic user, bool isAdmin, bool isBanned) {
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
          child: user.photoUrl == null 
            ? Text(user.name.isNotEmpty ? user.name[0].toUpperCase() : '?', 
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: isBanned ? pAlert : (isAdmin ? pDarkHeader : pTextMuted))) 
            : null,
        ),
        if (isAdmin) const Positioned(bottom: 0, right: 0, child: Icon(Icons.verified, color: Colors.blue, size: 16)),
      ],
    );
  }

  Widget _buildStats(dynamic user) {
    return Wrap(
      spacing: 6,
      children: [
        _miniPill(Icons.stars, '${user.points ?? 0} Puan'),
        _miniPill(Icons.price_change, '${user.priceEntries ?? 0} Fiyat'),
      ],
    );
  }

  Widget _miniPill(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(color: pStudio, borderRadius: BorderRadius.circular(4)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 10, color: pBrandBrown),
          const SizedBox(width: 4),
          Text(text, style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: pTextMain)),
        ],
      ),
    );
  }

  Widget _buildActionBar(BuildContext context, dynamic user, bool isBanned, bool isAdmin) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: const BoxDecoration(color: pBgApp, borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)), border: Border(top: BorderSide(color: pBorder))),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _actionBtn(Icons.edit, 'Düzenle', pBrandBrown, () => _showEditUserBottomSheet(context, ref, user)),
          _actionBtn(isBanned ? Icons.lock_open : Icons.block, isBanned ? 'Aç' : 'Ban', isBanned ? pSuccess : pAlert, () {
             ref.read(adminUserManagementDomainServiceProvider).setUserBanStatusByAdmin(
                userId: user.uid, isBanned: !isBanned, adminUid: FirebaseAuth.instance.currentUser?.uid);
          }),
          _actionBtn(Icons.person_remove, 'Sil', pAlert, () async {
            // Silme onayı ve işlemi...
          }),
          // Admin Switch
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Switch.adaptive(
                value: isAdmin, 
                activeColor: pBrandBrown,
                onChanged: (val) => ref.read(userNotifierProvider.notifier).toggleUserAdmin(user.uid, val)
              ),
              const Text('ADMIN', style: TextStyle(fontSize: 8, fontWeight: FontWeight.bold)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _actionBtn(IconData icon, String label, Color col, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Icon(icon, color: col, size: 20),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

// Bottom Sheet Fonksiyonu (Eski Dialog yerine Apple stili alttan kayan panel)
Future<void> _showEditUserBottomSheet(BuildContext context, WidgetRef ref, dynamic user) async {
  // ... (Bu kısmın kodunu zaten önceki mesajlarda vermiştik, düzenleme ekranı buraya gelecek)
}
