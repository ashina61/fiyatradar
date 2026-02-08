import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';
import '../models/notification_model.dart';
import 'firestore_service.dart';

class FcmService {
  FcmService({FirestoreService? firestoreService})
      : _firestoreService = firestoreService ?? FirestoreService();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FirestoreService _firestoreService;
  StreamSubscription<String>? _tokenSubscription;
  bool _handlersRegistered = false;
  String? _currentUserId;

  Future<void> configureForUser(String? userId) async {
    _currentUserId = userId;
    await _messaging.requestPermission(alert: true, badge: true, sound: true);
    _registerHandlers();

    await _tokenSubscription?.cancel();
    if (userId == null) {
      return;
    }

    final token = await _messaging.getToken();
    if (token != null) {
      await _firestoreService.updateUserFcmToken(userId, token);
    }

    _tokenSubscription = _messaging.onTokenRefresh.listen((token) {
      _firestoreService.updateUserFcmToken(userId, token);
    });
  }

  void _registerHandlers() {
    if (_handlersRegistered) return;
    FirebaseMessaging.onMessage.listen((message) {
      _handleMessage(message);
    });
    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      _handleMessage(message);
    });
    _handlersRegistered = true;
  }

  Future<void> _handleMessage(RemoteMessage message) async {
    final resolvedUserId = _currentUserId ?? message.data['userId'] as String?;
    if (resolvedUserId == null) return;

    final notification = message.notification;
    final data = message.data;
    final type = _parseType(data['type'] as String?);

    final model = NotificationModel(
      id: '',
      userId: resolvedUserId,
      type: type,
      title: notification?.title ?? (data['title'] as String? ?? 'Bildirim'),
      body: notification?.body ?? (data['body'] as String? ?? ''),
      productId: data['productId'] as String?,
      productName: data['productName'] as String?,
      imageUrl: data['imageUrl'] as String?,
      createdAt: DateTime.now(),
      data: data.isEmpty ? null : data,
    );

    await _firestoreService.addNotification(model);
  }

  NotificationType _parseType(String? raw) {
    if (raw == null) return NotificationType.system;
    return NotificationType.values.firstWhere(
      (type) => type.name == raw,
      orElse: () => NotificationType.system,
    );
  }
}
