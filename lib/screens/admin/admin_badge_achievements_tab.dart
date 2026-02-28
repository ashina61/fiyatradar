import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../utils/theme.dart';

class AdminBadgeAchievementsTab extends StatelessWidget {
  const AdminBadgeAchievementsTab({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('badge_achievements')
          .orderBy('timestamp', descending: true)
          .limit(100)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('Rozet kazanımları yüklenemedi.'),
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
          return const Center(child: Text('Henüz rozet kazanımı yok.'));
        }

        return ListView.separated(
          padding: const EdgeInsets.all(AppSpacing.md),
          itemCount: docs.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (context, index) {
            final data = docs[index].data();
            final ts = data['timestamp'];
            final date = ts is Timestamp ? ts.toDate() : null;
            return Card(
              child: ListTile(
                leading: const CircleAvatar(
                  child: Icon(Icons.workspace_premium_rounded),
                ),
                title: Text('Kullanıcı: ${(data['userId'] ?? '-').toString()}'),
                subtitle: Text('Rozet: ${(data['badgeId'] ?? '-').toString()}'),
                trailing: Text(
                  date == null
                      ? '-'
                      : '${date.day}.${date.month}.${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}',
                  style: Theme.of(context).textTheme.bodySmall,
                  textAlign: TextAlign.right,
                ),
              ),
            );
          },
        );
      },
    );
  }
}
