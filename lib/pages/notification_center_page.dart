import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../screens/product/product_detail_screen.dart';
import '../services/notification_center_service.dart';
import '../utils/theme.dart';

class NotificationCenterPage extends StatelessWidget {
  const NotificationCenterPage({super.key});

  @override
  Widget build(BuildContext context) {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) {
      return const Scaffold(
        body: Center(child: Text('Bildirimleri görmek için giriş yapmalısın.')),
      );
    }

    final service = NotificationCenterService();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Bildirim Merkezi'),
        actions: [
          TextButton(
            onPressed: () => service.markAllAsRead(userId),
            child: const Text('Tümünü okundu işaretle'),
          ),
        ],
      ),
      body: StreamBuilder<List<NotificationCenterItem>>(
        stream: service.getNotifications(userId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return const Center(child: Text('Bildirimler yüklenemedi.'));
          }

          final items = snapshot.data ?? const <NotificationCenterItem>[];
          if (items.isEmpty) {
            return const Center(child: Text('Henüz bildirimin yok.'));
          }

          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            itemBuilder: (context, index) {
              final item = items[index];
              return Material(
                color: item.isRead
                    ? AppColors.surfaceVariant.withOpacity(0.55)
                    : AppColors.surface,
                borderRadius: BorderRadius.circular(16),
                child: ListTile(
                  onTap: () async {
                    await service.markAsRead(userId, item.id);
                    if (!context.mounted || item.productId.isEmpty) return;
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => ProductDetailScreen(productId: item.productId),
                      ),
                    );
                  },
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  leading: Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: item.isRead ? Colors.transparent : AppColors.error,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: item.isRead
                            ? AppColors.outline.withOpacity(0.5)
                            : AppColors.error,
                      ),
                    ),
                  ),
                  title: Text(
                    item.title,
                    style: TextStyle(
                      fontWeight: item.isRead ? FontWeight.w600 : FontWeight.w800,
                    ),
                  ),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text('${item.body}\n${_formatTimeAgoTr(item.createdAt)}'),
                  ),
                  isThreeLine: true,
                ),
              );
            },
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemCount: items.length,
          );
        },
      ),
    );
  }

  static String _formatTimeAgoTr(DateTime? dateTime) {
    if (dateTime == null) return 'Az önce';
    final now = DateTime.now();
    final diff = now.difference(dateTime);

    if (diff.inMinutes < 1) return 'Az önce';
    if (diff.inMinutes < 60) return '${diff.inMinutes} dakika önce';
    if (diff.inHours < 24) return '${diff.inHours} saat önce';
    if (diff.inDays == 1) return 'Dün';
    if (diff.inDays < 7) return '${diff.inDays} gün önce';
    return '${dateTime.day}.${dateTime.month}.${dateTime.year}';
  }
}
