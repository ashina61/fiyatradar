import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../theme/fr_colors.dart';

class WatchlistScreen extends StatelessWidget {
  const WatchlistScreen({super.key, required this.userId});

  final String userId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: FRColors.bgApp,
      appBar: AppBar(
        backgroundColor: FRColors.bgApp,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        title: const Text('Fiyat Alarmlarım'),
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .collection('watchlist')
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return const _ExecutiveListFeedback(
              icon: CupertinoIcons.exclamationmark_triangle,
              title: 'Alarmlar yüklenemedi',
              message: 'Bir an sonra tekrar deneyebilirsin.',
            );
          }

          final docs = snapshot.data?.docs ?? const [];
          if (docs.isEmpty) {
            return const _ExecutiveListFeedback(
              icon: CupertinoIcons.bell,
              title: 'Aktif alarm bulunmuyor',
              message: 'Takip etmek istediğin ürünler için hedef fiyat belirleyebilirsin.',
            );
          }

          return _ExecutiveListCard(
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              itemCount: docs.length,
              separatorBuilder: (_, __) => const Divider(height: 1, color: FRColors.borderLight),
              itemBuilder: (context, index) {
                final data = docs[index].data();
                final productName = (data['productName'] ?? '').toString().trim();
                final title = productName.isEmpty ? 'Ürün' : productName;
                final targetPrice = (data['targetPrice'] as num?)?.toDouble();
                final targetText = targetPrice == null ? 'Hedef: —' : 'Hedef: ${_formatPrice(targetPrice)}';

                return _ExecutiveRow(
                  leading: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: FRColors.camel.withOpacity(0.14),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    alignment: Alignment.center,
                    child: const Icon(CupertinoIcons.bell, color: FRColors.camel, size: 19),
                  ),
                  title: Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: FRColors.espresso),
                  ),
                  subtitle: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: FRColors.espresso,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      targetText,
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: FRColors.camel),
                    ),
                  ),
                  trailing: IconButton(
                    onPressed: () => docs[index].reference.delete(),
                    icon: const Icon(CupertinoIcons.trash, color: FRColors.textHint, size: 20),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

class _ExecutiveListCard extends StatelessWidget {
  const _ExecutiveListCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: FRColors.surface,
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(color: FRColors.shadowSoft, blurRadius: 22, offset: Offset(0, 10)),
        ],
      ),
      child: child,
    );
  }
}

class _ExecutiveRow extends StatelessWidget {
  const _ExecutiveRow({
    required this.leading,
    required this.title,
    required this.subtitle,
    required this.trailing,
  });

  final Widget leading;
  final Widget title;
  final Widget subtitle;
  final Widget trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      child: Row(
        children: [
          leading,
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                title,
                const SizedBox(height: 6),
                subtitle,
              ],
            ),
          ),
          const SizedBox(width: 12),
          trailing,
        ],
      ),
    );
  }
}

class _ExecutiveListFeedback extends StatelessWidget {
  const _ExecutiveListFeedback({
    required this.icon,
    required this.title,
    required this.message,
  });

  final IconData icon;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 20),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
        decoration: BoxDecoration(
          color: FRColors.surface,
          borderRadius: BorderRadius.circular(24),
          boxShadow: const [
            BoxShadow(color: FRColors.shadowSoft, blurRadius: 22, offset: Offset(0, 10)),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: FRColors.camel, size: 28),
            const SizedBox(height: 14),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: FRColors.espresso),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: FRColors.textMuted),
            ),
          ],
        ),
      ),
    );
  }
}

String _formatPrice(num value) {
  final text = value % 1 == 0 ? value.toStringAsFixed(0) : value.toStringAsFixed(2).replaceAll('.', ',');
  return '$text ₺';
}
