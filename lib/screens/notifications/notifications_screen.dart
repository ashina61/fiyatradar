import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../utils/theme.dart';
import '../../widgets/premium_scaffold_shell.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      return const Scaffold(body: Center(child: Text('Kullanıcı oturumu bulunamadı.')));
    }

    final stream = FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('inbox')
        .orderBy('createdAt', descending: true)
        .snapshots();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Bildirimler'),
        actions: [
          TextButton(
            onPressed: () async {
              final snapshot = await FirebaseFirestore.instance
                  .collection('users')
                  .doc(uid)
                  .collection('inbox')
                  .where('read', isEqualTo: false)
                  .get();
              for (final doc in snapshot.docs) {
                await doc.reference.update({'read': true});
              }
            },
            child: Text(
              'Tümünü okundu yap',
              style: TextStyle(
                color: AppColors.primary, // Senin temanın ana rengi
                fontWeight: FontWeight.bold,
              ),
            ),
          )
        ],
      ),
      body: PremiumScaffoldShell(
        child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: stream,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('Bildirimler yüklenemedi.'),
                    const SizedBox(height: 8),
                    OutlinedButton(
                      onPressed: () => (context as Element).markNeedsBuild(),
                      child: const Text('Tekrar dene'),
                    ),
                  ],
                ),
              );
            }

            final docs = snapshot.data?.docs ?? const [];
            if (docs.isEmpty) {
              return const Center(child: Text('Henüz bildirimin yok.'));
            }

            return ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 22),
              itemCount: docs.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final doc = docs[index];
                final data = doc.data();
                final isRead = data['read'] == true;
                final ts = data['createdAt'];
                final date = ts is Timestamp ? ts.toDate() : null;
                
                // Başlığa göre dinamik ikon seçimi (İsteğe bağlı geliştirebilirsin)
                final titleStr = (data['title'] ?? '').toString().toLowerCase();
                IconData cardIcon = Icons.notifications_rounded;
                if (titleStr.contains('düştü') || titleStr.contains('fiyat')) {
                  cardIcon = Icons.trending_down_rounded;
                } else if (titleStr.contains('onay') || titleStr.contains('doğrula')) {
                  cardIcon = Icons.verified_rounded;
                }

                return TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0.92, end: 1),
                  duration: Duration(milliseconds: 220 + (index * 30)),
                  curve: Curves.easeOutCubic,
                  builder: (context, value, child) => Opacity(
                    opacity: value,
                    child: Transform.translate(offset: Offset(0, (1 - value) * 18), child: child),
                  ),
                  child: InkWell(
                    onTap: () {
                      if (!isRead) doc.reference.update({'read': true});
                    },
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        // OKUNMADIYSA: Temanın ana renginin çok saydam hali. OKUNDUYSA: Senin Surface rengin
                        color: isRead ? AppColors.surface : AppColors.primary.withOpacity(0.06),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isRead ? Colors.grey.withOpacity(0.15) : AppColors.primary.withOpacity(0.2),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Sol İkon Alanı
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: isRead ? Colors.grey.withOpacity(0.1) : AppColors.primary.withOpacity(0.12),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              cardIcon,
                              color: isRead ? Colors.grey.shade500 : AppColors.primary,
                              size: 22,
                            ),
                          ),
                          const SizedBox(width: 14),
                          // Sağ İçerik Alanı
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        (data['title'] ?? 'Bildirim').toString(),
                                        style: TextStyle(
                                          fontSize: 15,
                                          // Okunmadıysa ekstra kalın
                                          fontWeight: isRead ? FontWeight.bold : FontWeight.w800,
                                          color: Colors.black87,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      date == null ? '' : '${date.day}.${date.month}.${date.year}',
                                      style: TextStyle(
                                        fontSize: 12,
                                        // Okunmadıysa tarih de tema renginde ve kalın
                                        color: isRead ? Colors.grey.shade500 : AppColors.primary.withOpacity(0.9),
                                        fontWeight: isRead ? FontWeight.normal : FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  (data['body'] ?? '').toString(),
                                  style: TextStyle(
                                    fontSize: 14,
                                    // Okunmadıysa gövde metni de koyu ve vurgulu
                                    color: isRead ? Colors.grey.shade600 : Colors.black87,
                                    fontWeight: isRead ? FontWeight.normal : FontWeight.w600,
                                    height: 1.4,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
