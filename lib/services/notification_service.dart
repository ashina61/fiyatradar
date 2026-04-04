import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/notification_model.dart';
import '../utils/safe_query_builder.dart';

class NotificationService {
  NotificationService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  static const String channelId = 'high_importance_channel';
  static const String channelName = 'High Importance Notifications';
  static const String channelDescription =
      'This channel is used for important notifications.';
  static const bool _debugLogs = false;
  static const int _pageSize = 50;
  static const String _fcmTokenPrefsKey = 'fcm_token';

  static final FlutterLocalNotificationsPlugin _localNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  static const AndroidNotificationChannel _androidChannel =
      AndroidNotificationChannel(
        channelId,
        channelName,
        description: channelDescription,
        importance: Importance.high,
      );

  static bool _isLocalNotificationsInitialized = false;
  static bool _isTokenRefreshListenerRegistered = false;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> _userNotificationsRef(String userId) =>
      _firestore.collection('users').doc(userId).collection('notifications');

  void _log(String message) {
    if (!_debugLogs || !kDebugMode) return;
    debugPrint('[notifications] $message');
  }

  static Future<void> initializeLocalNotifications() async {
    if (_isLocalNotificationsInitialized) return;

    const initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: DarwinInitializationSettings(),
    );

    await _localNotificationsPlugin.initialize(initializationSettings);
    await _localNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(_androidChannel);

    _isLocalNotificationsInitialized = true;
  }

  Future<String?> getFCMToken() async {
    _registerTokenRefreshListener();
    final token = await FirebaseMessaging.instance.getToken();
    await _cacheToken(token);
    return token;
  }

  Future<String?> getCachedFCMToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_fcmTokenPrefsKey);
  }

  void _registerTokenRefreshListener() {
    if (_isTokenRefreshListenerRegistered) return;
    FirebaseMessaging.instance.onTokenRefresh.listen(_cacheToken);
    _isTokenRefreshListenerRegistered = true;
  }

  static Future<void> _cacheToken(String? token) async {
    if (token == null || token.isEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_fcmTokenPrefsKey, token);
  }

  Future<void> setupForegroundNotifications() async {
    await initializeLocalNotifications();
    FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
      final notification = message.notification;
      if (notification == null) return;
      await _localNotificationsPlugin.show(
        notification.hashCode,
        notification.title,
        notification.body,
        NotificationDetails(
          android: AndroidNotificationDetails(
            channelId,
            channelName,
            channelDescription: channelDescription,
            importance: Importance.max,
            priority: Priority.high,
            icon: '@mipmap/ic_launcher',
          ),
          iOS: const DarwinNotificationDetails(),
        ),
      );
    });
  }

  void setupNotificationOpenedApp() {
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      if (kDebugMode) debugPrint('Notification tapped: ${message.data}');
    });
  }

  static Future<void> requestNotificationPermissions() async {
    await FirebaseMessaging.instance.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.iOS) {
      await _localNotificationsPlugin
          .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(alert: true, badge: true, sound: true);
    }
  }

  Stream<List<NotificationItem>> watchUserNotifications(String userId) {
    return _userNotificationsRef(userId)
        .orderBy('createdAt', descending: true)
        .limit(_pageSize)
        .snapshots()
        .map((snapshot) {
      final items = snapshot.docs
          .map(NotificationItem.fromFirestoreDoc)
          .toList(growable: false);
      _log('uid=$userId docs=${items.length} unread=${items.where((e) => !e.isRead).length}');
      return List<NotificationItem>.unmodifiable(items);
    });
  }

  Stream<List<NotificationItem>> watchNotifications(String userId) =>
      watchUserNotifications(userId);
  Stream<List<NotificationItem>> getNotifications(String userId) =>
      watchUserNotifications(userId);
  Stream<int> getUnreadNotificationCount(String userId) =>
      watchUserNotifications(userId)
          .map((list) => list.where((item) => !item.isRead).length);

  Future<void> addUserNotification(String userId, NotificationItem notification) async {
    final ref = notification.id.trim().isEmpty
        ? _userNotificationsRef(userId).doc()
        : _userNotificationsRef(userId).doc(notification.id);
    await ref.set({
      'id': ref.id,
      'type': notification.type,
      'title': notification.title,
      'message': notification.message,
      'isRead': notification.isRead,
      'createdAt': FieldValue.serverTimestamp(),
      'metaData': {
        ...notification.metaData,
        if (!notification.metaData.containsKey('eventId')) 'eventId': ref.id,
      },
    }, SetOptions(merge: true));
  }

  Future<void> addNotification(NotificationItem notification) async {
    final userId = notification.userId.trim();
    if (userId.isEmpty) {
      throw StateError('Notification userId is required for write');
    }
    await addUserNotification(userId, notification);
  }

  Future<void> markAsRead(String userId, String id) async {
    await _userNotificationsRef(userId).doc(id).update({'isRead': true});
  }

  Future<void> markRead(String userId, String notificationId) =>
      markAsRead(userId, notificationId);

  Future<void> markNotificationAsRead(String notificationId) async {
    final docs = await _firestore
        .collectionGroup('notifications')
        .where(FieldPath.documentId, isEqualTo: notificationId)
        .limit(1)
        .get();
    if (docs.docs.isNotEmpty) {
      await docs.docs.first.reference.update({'isRead': true});
    }
  }

  Future<void> markAllAsRead(String userId) async {
    final snapshot = await _userNotificationsRef(userId)
        .where('isRead', isEqualTo: false)
        .get();
    final batch = _firestore.batch();
    for (final doc in snapshot.docs) {
      batch.update(doc.reference, {'isRead': true});
    }
    await batch.commit();
  }

  Future<void> markAllRead(String userId) => markAllAsRead(userId);
  Future<void> markAllNotificationsAsRead(String userId) => markAllAsRead(userId);

  Future<void> deleteNotification(String notificationId) async {
    final docs = await _firestore
        .collectionGroup('notifications')
        .where(FieldPath.documentId, isEqualTo: notificationId)
        .limit(1)
        .get();
    if (docs.docs.isNotEmpty) {
      await docs.docs.first.reference.delete();
    }
  }

  Future<void> sendToUser(
    String userId,
    String title,
    String body,
    String type,
    String? productId,
  ) async {
    final normalizedUserId = userId.trim();
    if (normalizedUserId.isEmpty) return;
    await addUserNotification(
      normalizedUserId,
      NotificationItem(
        id: '',
        type: type,
        title: title,
        message: body,
        isRead: false,
        createdAt: Timestamp.now(),
        metaData: {
          'userId': normalizedUserId,
          if (productId != null && productId.isNotEmpty) 'productId': productId,
        },
      ),
    );
  }

  Future<int> sendToWatchlistUsers(
    String productId,
    String title,
    String body,
    String type,
  ) async {
    final normalizedProductId = productId.trim();
    if (normalizedProductId.isEmpty) return 0;

    final watchedSnapshot = await SafeQueryBuilder.safeWhere(
      _firestore.collectionGroup('followedProducts'),
      FieldPath.documentId,
      normalizedProductId,
      expectedType: String,
    ).get();
    if (watchedSnapshot.docs.isEmpty) return 0;

    final batch = _firestore.batch();
    var sentCount = 0;
    for (final watchDoc in watchedSnapshot.docs) {
      final userRef = watchDoc.reference.parent.parent;
      final uid = userRef?.id;
      if (uid == null || uid.trim().isEmpty) continue;
      final itemRef = _userNotificationsRef(uid).doc();
      batch.set(itemRef, {
        'id': itemRef.id,
        'type': type,
        'title': title,
        'message': body,
        'isRead': false,
        'createdAt': FieldValue.serverTimestamp(),
        'metaData': {
          'userId': uid,
          'productId': normalizedProductId,
          'eventId': itemRef.id,
        },
      });
      sentCount += 1;
    }
    if (sentCount > 0) await batch.commit();
    return sentCount;
  }

  Future<int> sendSystemToAllUsers(String body) async {
    final users = await _firestore.collection('users').get();
    var sentCount = 0;
    for (final userDoc in users.docs) {
      await sendToUser(userDoc.id, '🔧 Sistem Bildirimi', body, 'system', null);
      sentCount += 1;
    }
    return sentCount;
  }
}
