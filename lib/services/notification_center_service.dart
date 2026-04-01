import 'package:cloud_firestore/cloud_firestore.dart';

class NotificationCenterItem {
  NotificationCenterItem({
    required this.id,
    required this.title,
    required this.body,
    required this.productId,
    required this.isRead,
    required this.createdAt,
  });

  final String id;
  final String title;
  final String body;
  final String productId;
  final bool isRead;
  final DateTime? createdAt;

  factory NotificationCenterItem.fromDoc(
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data();
    final createdAtRaw = data['createdAt'];
    final metaDataRaw = data['metaData'];
    final metaData = metaDataRaw is Map<String, dynamic>
        ? metaDataRaw
        : <String, dynamic>{};
    return NotificationCenterItem(
      id: doc.id,
      title: (data['title'] ?? 'Bildirim').toString(),
      body: (data['message'] ?? data['body'] ?? '').toString(),
      productId: (data['productId'] ?? metaData['productId'] ?? '').toString(),
      isRead: data['isRead'] == true || data['read'] == true,
      createdAt: createdAtRaw is Timestamp ? createdAtRaw.toDate() : null,
    );
  }
}

class NotificationCenterService {
  NotificationCenterService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> _canonicalRef(String userId) =>
      _firestore.collection('users').doc(userId).collection('notifications');

  Stream<List<NotificationCenterItem>> getNotifications(String userId) {
    return _canonicalRef(userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map(NotificationCenterItem.fromDoc)
              .toList(growable: false),
        );
  }

  Future<void> markAsRead(String userId, String notificationId) async {
    await _canonicalRef(userId).doc(notificationId).update({'isRead': true});
  }

  Future<void> markAllAsRead(String userId) async {
    final canonicalUnread = await _canonicalRef(userId).where('isRead', isEqualTo: false).get();
    if (canonicalUnread.docs.isEmpty) {
      return;
    }

    final batch = _firestore.batch();
    for (final doc in canonicalUnread.docs) {
      batch.update(doc.reference, {'isRead': true});
    }
    await batch.commit();
  }

  Stream<int> getUnreadCount(String userId) {
    return getNotifications(userId)
        .map((items) => items.where((item) => !item.isRead).length);
  }
}
