import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../theme/fr_colors.dart';

class MyPricesScreen extends StatelessWidget {
  const MyPricesScreen({super.key, required this.userId});

  final String userId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: FRColors.bgApp,
      appBar: AppBar(
        backgroundColor: FRColors.bgApp,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        title: const Text('Eklediğim Fiyatlar'),
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('priceReports')
            .where('createdByUid', isEqualTo: userId)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return const _ExecutiveListFeedback(
              icon: CupertinoIcons.exclamationmark_triangle,
              title: 'Fiyat geçmişi yüklenemedi',
              message: 'Lütfen birazdan tekrar dene.',
            );
          }

          final docs = (snapshot.data?.docs ?? const [])
              .where((doc) => (doc.data()['status'] ?? '').toString() == 'active')
              .toList()
            ..sort((a, b) {
              final aTs = a.data()['createdAt'] as Timestamp?;
              final bTs = b.data()['createdAt'] as Timestamp?;
              final aDt = aTs?.toDate() ?? DateTime.fromMillisecondsSinceEpoch(0);
              final bDt = bTs?.toDate() ?? DateTime.fromMillisecondsSinceEpoch(0);
              return bDt.compareTo(aDt);
            });

          if (docs.isEmpty) {
            return const _ExecutiveListFeedback(
              icon: CupertinoIcons.tag,
              title: 'Henüz fiyat eklemedin',
              message: 'Yeni fiyat girişlerin burada premium bir geçmiş olarak görünecek.',
            );
          }

          return _ExecutiveListCard(
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              itemCount: docs.length,
              separatorBuilder: (_, __) => const Divider(height: 1, color: FRColors.borderLight),
              itemBuilder: (context, index) {
                final data = docs[index].data();
                final ts = data['createdAt'];
                final date = ts is Timestamp ? ts.toDate() : null;
                final productName = (data['productName'] ?? data['urunAdi'] ?? data['name'] ?? data['title'] ?? '')
                    .toString()
                    .trim();
                final displayName = productName.isEmpty ? 'İsimsiz Ürün' : productName;
                final storeName = (data['storeName'] ?? 'Market').toString().trim();
                final dateText = date == null ? 'Tarih yok' : DateFormat('d MMM y', 'tr_TR').format(date);
                final price = (data['price'] as num?) ?? 0;

                return _ExecutiveRow(
                  leading: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: FRColors.background,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    alignment: Alignment.center,
                    child: const Icon(CupertinoIcons.tag, color: FRColors.espresso, size: 18),
                  ),
                  title: Text(
                    displayName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: FRColors.espresso),
                  ),
                  subtitle: Text(
                    '$storeName • $dateText',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: FRColors.textMuted),
                  ),
                  trailing: _PriceText(value: price),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

class _PriceText extends StatelessWidget {
  const _PriceText({required this.value});

  final num value;

  @override
  Widget build(BuildContext context) {
    final priceText = value % 1 == 0 ? value.toStringAsFixed(0) : value.toStringAsFixed(2).replaceAll('.', ',');
    return RichText(
      textAlign: TextAlign.right,
      text: TextSpan(
        children: [
          TextSpan(
            text: priceText,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w900,
              color: FRColors.espresso,
              letterSpacing: -0.4,
            ),
          ),
          const TextSpan(
            text: ' ₺',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: FRColors.espresso,
            ),
          ),
        ],
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
                const SizedBox(height: 4),
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
