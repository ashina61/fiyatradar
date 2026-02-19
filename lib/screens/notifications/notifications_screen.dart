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
        .collection('notifications')
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
                  .collection('notifications')
                  .where('read', isEqualTo: false)
                  .get();
              for (final doc in snapshot.docs) {
                await doc.reference.update({'read': true});
              }
            },
            child: const Text('Tümünü okundu yap'),
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
                    OutlinedButton(onPressed: () => (context as Element).markNeedsBuild(), child: const Text('Tekrar dene')),
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
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final doc = docs[index];
                final data = doc.data();
                final read = data['read'] == true;
                final ts = data['createdAt'];
                final date = ts is Timestamp ? ts.toDate() : null;
                return TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0.92, end: 1),
                  duration: Duration(milliseconds: 220 + (index * 30)),
                  curve: Curves.easeOutCubic,
                  builder: (context, value, child) => Opacity(
                    opacity: value,
                    child: Transform.translate(offset: Offset(0, (1 - value) * 18), child: child),
                  ),
                  child: Material(
                    color: AppColors.surface.withOpacity(read ? 0.86 : 0.96),
                    borderRadius: BorderRadius.circular(18),
                    child: ListTile(
                      onTap: () => doc.reference.update({'read': true}),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                      leading: Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: (read ? AppColors.success : AppColors.primary).withOpacity(0.14),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          read ? Icons.mark_email_read_rounded : Icons.mark_email_unread_rounded,
                          color: read ? AppColors.success : AppColors.primary,
                        ),
                      ),
                      title: Text((data['title'] ?? 'Bildirim').toString(), style: const TextStyle(fontWeight: FontWeight.w700)),
                      subtitle: Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text((data['body'] ?? '').toString()),
                      ),
                      trailing: Text(date == null ? '' : '${date.day}.${date.month}.${date.year}', style: const TextStyle(fontSize: 12)),
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
