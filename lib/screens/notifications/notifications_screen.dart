import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

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
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
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
            itemCount: docs.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final doc = docs[index];
              final data = doc.data();
              final read = data['read'] == true;
              final ts = data['createdAt'];
              final date = ts is Timestamp ? ts.toDate() : null;
              return ListTile(
                onTap: () => doc.reference.update({'read': true}),
                leading: Icon(read ? Icons.mark_email_read_rounded : Icons.mark_email_unread_rounded, color: read ? Colors.green : Colors.orange),
                title: Text((data['title'] ?? 'Bildirim').toString()),
                subtitle: Text((data['body'] ?? '').toString()),
                trailing: Text(date == null ? '' : '${date.day}.${date.month}.${date.year}', style: const TextStyle(fontSize: 12)),
              );
            },
          );
        },
      ),
    );
  }
}
