import 'dart:async';

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
      isRead: data['isRead'] == true || data['read'] == true,
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

  CollectionReference<Map<String, dynamic>> _userInAppRef(String userId) =>
      _firestore.collection('users').doc(userId).collection('inAppNotifications');

  Stream<List<NotificationCenterItem>> getNotifications(String userId) {
    final legacyStream = _itemsRef(userId)
        .orderBy('createdAt', descending: true)
        .snapshots();
    final userScopedStream = _userInAppRef(userId)
        .orderBy('createdAt', descending: true)
        .snapshots();

    return _combineNotificationStreams(legacyStream, userScopedStream);
  }

  Stream<List<NotificationCenterItem>> _combineNotificationStreams(
    Stream<QuerySnapshot<Map<String, dynamic>>> legacyStream,
    Stream<QuerySnapshot<Map<String, dynamic>>> userScopedStream,
  ) {
    late StreamController<List<NotificationCenterItem>> controller;
    StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? legacySub;
    StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? userScopedSub;

    QuerySnapshot<Map<String, dynamic>>? latestLegacy;
    QuerySnapshot<Map<String, dynamic>>? latestUserScoped;

    void emitMerged() {
      final merged = <String, NotificationCenterItem>{};

      void addFrom(QuerySnapshot<Map<String, dynamic>>? snapshot) {
        if (snapshot == null) return;
        for (final doc in snapshot.docs) {
          final item = NotificationCenterItem.fromDoc(doc);
          merged.putIfAbsent(item.id, () => item);
        }
      }

      addFrom(latestLegacy);
      addFrom(latestUserScoped);

      final list = merged.values.toList(growable: false)
        ..sort((a, b) {
          final aMs = a.createdAt?.millisecondsSinceEpoch ?? 0;
          final bMs = b.createdAt?.millisecondsSinceEpoch ?? 0;
          return bMs.compareTo(aMs);
        });

      controller.add(list);
    }

    controller = StreamController<List<NotificationCenterItem>>.broadcast(
      onListen: () {
        legacySub = legacyStream.listen(
          (snapshot) {
            latestLegacy = snapshot;
            emitMerged();
          },
          onError: controller.addError,
        );

        userScopedSub = userScopedStream.listen(
          (snapshot) {
            latestUserScoped = snapshot;
            emitMerged();
          },
          onError: controller.addError,
        );
      },
      onCancel: () async {
        await legacySub?.cancel();
        await userScopedSub?.cancel();
      },
    );

    return controller.stream;
  }

  Future<void> markAsRead(String userId, String notificationId) async {
    try {
      await _itemsRef(userId).doc(notificationId).update({'isRead': true});
      return;
    } catch (_) {
      await _userInAppRef(userId).doc(notificationId).update({'read': true});
    }
  }

  Future<void> markAllAsRead(String userId) async {
    final unread = await _itemsRef(userId).where('isRead', isEqualTo: false).get();
    final userUnread = await _userInAppRef(userId).where('read', isEqualTo: false).get();
    if (unread.docs.isEmpty && userUnread.docs.isEmpty) return;

    final batch = _firestore.batch();
    for (final doc in unread.docs) {
      batch.update(doc.reference, {'isRead': true});
    }
    for (final doc in userUnread.docs) {
      batch.update(doc.reference, {'read': true});
    }
    await batch.commit();
  }

  Stream<int> getUnreadCount(String userId) {
    return getNotifications(userId)
        .map((items) => items.where((item) => !item.isRead).length);
  }
}
