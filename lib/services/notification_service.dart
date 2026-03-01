import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../models/notification_model.dart';
import '../utils/safe_query_builder.dart';

class NotificationService {
  NotificationService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  static const bool _debugLogs = false;
  static const int _inboxPageSize = 50;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _globalPrimaryRef =>
      _firestore.collection('inAppNotifications');
  CollectionReference<Map<String, dynamic>> get _globalLegacyRef =>
      _firestore.collection('notifications');

  CollectionReference<Map<String, dynamic>> _userInboxRef(String userId) =>
      _firestore.collection('users').doc(userId).collection('inbox');

  DocumentReference<Map<String, dynamic>> _userMetaRef(String userId) =>
      _firestore.collection('users').doc(userId);

  void _log(String message) {
    if (!_debugLogs || !kDebugMode) return;
    debugPrint('[inbox] $message');
  }

  Stream<List<NotificationItem>> watchInbox(String userId) {
    final query = _userInboxRef(userId)
        .orderBy('createdAt', descending: true)
        .limit(_inboxPageSize);

    return query.snapshots().map((snapshot) {
      final list = snapshot.docs
          .map(NotificationItem.fromPrimaryDoc)
          .toList(growable: false);
      final unread = list.where((n) => !n.read).length;
      _log('uid=$userId docs=${list.length} unread=$unread');
      return List<NotificationItem>.unmodifiable(List<NotificationItem>.from(list));
    });
  }

  Stream<List<NotificationItem>> watchNotifications(String userId) {
    return watchInbox(userId);
  }

  Stream<List<NotificationItem>> getNotifications(String userId) {
    return watchInbox(userId);
  }

  Stream<int> getUnreadNotificationCount(String userId) {
    return watchInbox(userId)
        .map((list) => list.where((item) => !item.read).length);
  }

  Future<void> addInboxNotification(String userId, NotificationItem notification) async {
    final ref = _userInboxRef(userId).doc();
    await ref.set({
      'id': ref.id,
      'type': _typeToWire(notification.type),
      'title': notification.title,
      'body': notification.body,
      'createdAt': FieldValue.serverTimestamp(),
      'read': false,
      'meta': {
        ...notification.meta,
        if (!notification.meta.containsKey('eventId')) 'eventId': ref.id,
      },
    }, SetOptions(merge: true));
  }

  Future<void> addNotification(NotificationItem notification) async {
    final userId = notification.userId;
    if (userId.isEmpty) {
      throw StateError('Notification userId is required for inbox write');
    }
    await addInboxNotification(userId, notification);
  }

  Future<void> markRead(String userId, String notificationId) async {
    await _userInboxRef(userId).doc(notificationId).update({'read': true});
  }

  Future<void> markNotificationAsRead(String notificationId) async {
    final inboxDocs = await _firestore
        .collectionGroup('inbox')
        .where(FieldPath.documentId, isEqualTo: notificationId)
        .limit(1)
        .get();
    if (inboxDocs.docs.isNotEmpty) {
      await inboxDocs.docs.first.reference.update({'read': true});
    }
  }

  Future<void> markAllRead(String userId) async {
    final snapshot = await _userInboxRef(userId).where('read', isEqualTo: false).get();
    final batch = _firestore.batch();
    for (final doc in snapshot.docs) {
      batch.update(doc.reference, {'read': true});
    }
    await batch.commit();
  }

  Future<void> markAllNotificationsAsRead(String userId) async {
    await markAllRead(userId);
  }

  Future<void> migrateLegacyToInboxIfNeeded(String userId) async {
    final metaDoc = await _userMetaRef(userId).get();
    final meta = metaDoc.data()?['meta'];
    final migrated = meta is Map<String, dynamic> && meta['notificationsMigrated'] == true;
    if (migrated) return;

    _log('migration start uid=$userId');

    final legacyGlobal = await SafeQueryBuilder.safeWhere(
      _globalLegacyRef,
      'userId',
      userId,
      expectedType: String,
    ).get();
    final primaryGlobal = await SafeQueryBuilder.safeWhere(
      _globalPrimaryRef,
      'userId',
      userId,
      expectedType: String,
    ).get();

    final legacyUser = await _firestore
        .collection('users')
        .doc(userId)
        .collection('notifications')
        .get();

    final allDocs = <QueryDocumentSnapshot<Map<String, dynamic>>>[
      ...legacyGlobal.docs,
      ...primaryGlobal.docs,
      ...legacyUser.docs,
    ];

    final byMigrationKey = <String, NotificationItem>{};
    for (final doc in allDocs) {
      final raw = doc.data();
      final hasRead = raw.containsKey('read');
      final mapped = hasRead
          ? NotificationItem.fromPrimaryDoc(doc)
          : NotificationItem.fromLegacyDoc(doc);
      final eventId = mapped.meta['eventId']?.toString();
      final key = (eventId != null && eventId.isNotEmpty) ? 'event:$eventId' : 'legacy:${doc.id}';
      byMigrationKey.putIfAbsent(key, () => mapped);
    }

    final batch = _firestore.batch();
    for (final item in byMigrationKey.values) {
      final inboxRef = _userInboxRef(userId).doc(item.id);
      batch.set(inboxRef, {
        'id': inboxRef.id,
        'type': _typeToWire(item.type),
        'title': item.title,
        'body': item.body,
        'createdAt': Timestamp.fromDate(item.createdAt),
        'read': item.read,
        'meta': item.meta,
      }, SetOptions(merge: true));
    }

    batch.set(_userMetaRef(userId), {
      'meta': {'notificationsMigrated': true}
    }, SetOptions(merge: true));

    await batch.commit();
    _log('migration end uid=$userId legacy=${allDocs.length} migrated=${byMigrationKey.length}');
  }

  Future<void> deleteNotification(String notificationId) async {
    final inboxDocs = await _firestore
        .collectionGroup('inbox')
        .where(FieldPath.documentId, isEqualTo: notificationId)
        .limit(1)
        .get();
    if (inboxDocs.docs.isNotEmpty) {
      await inboxDocs.docs.first.reference.delete();
    }
  }

  String _typeToWire(NotificationType type) {
    return switch (type) {
      NotificationType.priceDrop => 'price_drop',
      NotificationType.newPrice => 'new_price',
      NotificationType.system => 'system',
    };
  }
}
