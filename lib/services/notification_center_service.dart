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
    return NotificationCenterItem(
      id: doc.id,
      title: (data['title'] ?? 'Bildirim').toString(),
      body: (data['body'] ?? '').toString(),
      productId: (data['productId'] ?? '').toString(),
      isRead: data['isRead'] == true,
      createdAt: createdAtRaw is Timestamp ? createdAtRaw.toDate() : null,
    );
  }
}

class NotificationCenterService {
  NotificationCenterService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> _itemsRef(String userId) =>
      _firestore.collection('notifications').doc(userId).collection('items');

  Stream<List<NotificationCenterItem>> getNotifications(String userId) {
    return _itemsRef(userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map(NotificationCenterItem.fromDoc)
              .toList(growable: false),
        );
  }

  Future<void> markAsRead(String userId, String notificationId) {
    return _itemsRef(userId).doc(notificationId).update({'isRead': true});
  }

  Future<void> markAllAsRead(String userId) async {
    final unread = await _itemsRef(userId).where('isRead', isEqualTo: false).get();
    if (unread.docs.isEmpty) return;

    final batch = _firestore.batch();
    for (final doc in unread.docs) {
      batch.update(doc.reference, {'isRead': true});
    }
    await batch.commit();
  }

  Stream<int> getUnreadCount(String userId) {
    return _itemsRef(userId)
        .where('isRead', isEqualTo: false)
        .snapshots()
        .map((snapshot) => snapshot.size);
  }
}
