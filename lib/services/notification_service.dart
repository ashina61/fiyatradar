import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/notification_model.dart';
import '../utils/safe_query_builder.dart';

class NotificationService {
  NotificationService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _notificationsRef =>
      _firestore.collection('inAppNotifications');
  CollectionReference<Map<String, dynamic>> get _legacyNotificationsRef =>
      _firestore.collection('notifications');

  Stream<List<NotificationModel>> getNotifications(String userId) {
    final primary = SafeQueryBuilder.safeWhere(
      _notificationsRef,
      'userId',
      userId,
      expectedType: String,
    ).snapshots();
    final legacy = SafeQueryBuilder.safeWhere(
      _legacyNotificationsRef,
      'userId',
      userId,
      expectedType: String,
    ).snapshots();

    return primary.asyncMap((primarySnapshot) async {
      final legacySnapshot = await legacy.first;
      final merged = <NotificationModel>[
        ...primarySnapshot.docs.map(NotificationModel.fromFirestore),
        ...legacySnapshot.docs.map(NotificationModel.fromFirestore),
      ];

      final byId = <String, NotificationModel>{};
      for (final notification in merged) {
        byId[notification.id] = notification;
      }
      final list = byId.values.toList();
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return list;
    });
  }

  Stream<int> getUnreadNotificationCount(String userId) {
    return getNotifications(userId).map(
      (list) => list.where((item) => !item.isRead).length,
    );
  }

  Future<void> markNotificationAsRead(String notificationId) async {
    final doc = await _notificationsRef.doc(notificationId).get();
    if (doc.exists) {
      await _notificationsRef.doc(notificationId).update({'isRead': true});
      return;
    }

    final legacyDoc = await _legacyNotificationsRef.doc(notificationId).get();
    if (legacyDoc.exists) {
      await _legacyNotificationsRef.doc(notificationId).update({'isRead': true});
    }
  }

  Future<void> markAllNotificationsAsRead(String userId) async {
    final batch = _firestore.batch();
    final primarySnapshot = await SafeQueryBuilder.safeWhere(
      _notificationsRef,
      'userId',
      userId,
      expectedType: String,
    ).get();
    final legacySnapshot = await SafeQueryBuilder.safeWhere(
      _legacyNotificationsRef,
      'userId',
      userId,
      expectedType: String,
    ).get();

    for (final doc in [...primarySnapshot.docs, ...legacySnapshot.docs]) {
      final raw = doc.data();
      final map =
          raw is Map<String, dynamic> ? Map<String, dynamic>.from(raw) : <String, dynamic>{};
      final isRead = map['isRead'] == true;
      if (!isRead) {
        batch.update(doc.reference, {'isRead': true});
      }
    }

    await batch.commit();
  }

  Future<void> addNotification(NotificationModel notification) async {
    await _notificationsRef.add(notification.toFirestore());
  }

  Future<void> deleteNotification(String notificationId) async {
    await _notificationsRef.doc(notificationId).delete();
  }
}
