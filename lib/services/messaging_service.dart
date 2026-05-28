import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import 'firebase_service.dart';

/// Top-level background handler. Must be a top-level (or static) function so
/// the Flutter engine can spin it up in its own isolate. We only log here —
/// `notification` payloads are already rendered by the system tray when the
/// app is backgrounded, so there's nothing to draw. Kept lightweight on
/// purpose: the background isolate doesn't have the rest of the app wired up.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint(
    'BACKGROUND_MESSAGE_RECEIVED: title=${message.notification?.title} '
    'data=${message.data}',
  );
}

/// Android notification channel id — MUST match the
/// `com.google.firebase.messaging.default_notification_channel_id` meta-data
/// declared in AndroidManifest.xml so background `notification` payloads land
/// in the same channel the foreground local notifications use.
const String _kAndroidChannelId = 'high_importance_channel';

/// Wires `firebase_messaging` to the Firestore-backed notification system the
/// Cloud Functions (`functions/index.js`) already target.
///
/// Responsibilities:
///   • Request runtime permission (Android 13+ / iOS) and expose the result so
///     the UI can warn the user when notifications are blocked.
///   • Create the Android notification channel (otherwise Android 8+ silently
///     drops notifications targeting a non-existent channel).
///   • Persist the device FCM token to `users/{uid}.fcmToken`.
///   • Refresh the token after auth changes and on `onTokenRefresh`.
///   • Render a local notification for foreground messages (FCM does NOT show
///     `notification` payloads while the app is in the foreground).
class MessagingService {
  MessagingService._();
  static final MessagingService instance = MessagingService._();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FirebaseService _svc = FirebaseService.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  StreamSubscription<String>? _tokenRefreshSub;
  StreamSubscription<RemoteMessage>? _foregroundSub;
  StreamSubscription<User?>? _authSub;

  String? _activeUid;
  String? _lastWrittenToken;
  bool _initialized = false;
  bool _localSetupDone = false;

  /// Push iznin son bilinen durumu. UI (`notifications_screen`) bunu okuyup
  /// izin kapalıyken görünür bir uyarı gösterir. Notifier reaktif —
  /// `init()` izni aldıktan sonra dinleyiciler güncellenir.
  final ValueNotifier<bool> notificationsBlocked = ValueNotifier<bool>(false);

  Future<void> init() async {
    if (_initialized) return;
    _initialized = true;

    debugPrint('NOTIFICATION_INIT_START');

    // Background handler'ı izin/akış kurulmadan önce kaydet — uygulama arka
    // plandayken gelen mesajların isolate'i hazır olsun.
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    await _setUpLocalNotifications();

    try {
      final settings = await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );
      final status = settings.authorizationStatus;
      final granted = status == AuthorizationStatus.authorized ||
          status == AuthorizationStatus.provisional;
      notificationsBlocked.value = !granted;
      debugPrint(
        'NOTIFICATION_PERMISSION_STATUS: '
        '${granted ? 'authorized' : 'denied'} (${status.name})',
      );
    } catch (e) {
      // İzin alınamazsa kullanıcı bildirim alamayacağı için bloklu kabul et;
      // sessizce yutma — sebebini logla.
      notificationsBlocked.value = true;
      debugPrint('NOTIFICATION_PERMISSION_STATUS: denied (error=$e)');
    }

    // Foreground'da iOS'un da banner göstermesi için (Android'de etkisiz).
    try {
      await _messaging.setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );
    } catch (e) {
      debugPrint('FCM setForegroundPresentationOptions failed: $e');
    }

    _authSub = FirebaseAuth.instance.authStateChanges().listen((user) {
      _activeUid = user?.uid;
      if (user == null || user.isAnonymous) {
        // Anonymous sessions don't get push — they'd just orphan tokens.
        _lastWrittenToken = null;
        return;
      }
      unawaited(_syncTokenForUser(user.uid));
    });

    final current = FirebaseAuth.instance.currentUser;
    if (current != null && !current.isAnonymous) {
      _activeUid = current.uid;
      unawaited(_syncTokenForUser(current.uid));
    }

    _tokenRefreshSub = _messaging.onTokenRefresh.listen((token) {
      debugPrint('FCM_TOKEN_REFRESHED');
      final uid = _activeUid;
      if (uid == null || uid.isEmpty) return;
      // Refresh edilen token mutlaka yeniden yazılmalı — eskisini geçersiz say.
      _lastWrittenToken = null;
      unawaited(_writeToken(uid: uid, token: token));
    });

    _foregroundSub = FirebaseMessaging.onMessage.listen((message) {
      debugPrint(
        'FOREGROUND_MESSAGE_RECEIVED: ${message.notification?.title} · '
        '${message.data}',
      );
      // Cloud Function zaten `users/{uid}/notifications/{id}` doc'u yazıyor
      // (in-app merkez stream'i yakalıyor). Ama foreground'da FCM sistem
      // bildirimini ÇİZMEZ — kullanıcı uygulamadayken görsün diye yerel
      // bildirim gösteriyoruz.
      unawaited(_showLocalNotification(message));
    });
  }

  Future<void> _setUpLocalNotifications() async {
    if (_localSetupDone) return;
    try {
      const androidInit =
          AndroidInitializationSettings('@mipmap/ic_launcher');
      const initSettings = InitializationSettings(
        android: androidInit,
        iOS: DarwinInitializationSettings(),
      );
      await _localNotifications.initialize(initSettings);

      final androidPlugin =
          _localNotifications.resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();
      if (androidPlugin != null) {
        const channel = AndroidNotificationChannel(
          _kAndroidChannelId,
          'Fiyat Alarmları',
          description: 'Fiyat düşüşleri, doğrulamalar ve radar sinyalleri.',
          importance: Importance.high,
        );
        await androidPlugin.createNotificationChannel(channel);
        debugPrint('NOTIFICATION_CHANNEL_CREATED: $_kAndroidChannelId');
      }
      _localSetupDone = true;
    } catch (e) {
      debugPrint('Local notification setup failed: $e');
    }
  }

  Future<void> _showLocalNotification(RemoteMessage message) async {
    final notification = message.notification;
    // Yalnız title/body olan mesajları çiziyoruz; data-only mesajlar in-app
    // doc üzerinden zaten görünür.
    final title = notification?.title ?? message.data['title']?.toString();
    final body = notification?.body ?? message.data['body']?.toString();
    if ((title == null || title.isEmpty) && (body == null || body.isEmpty)) {
      return;
    }
    if (!_localSetupDone) {
      await _setUpLocalNotifications();
    }
    try {
      const details = NotificationDetails(
        android: AndroidNotificationDetails(
          _kAndroidChannelId,
          'Fiyat Alarmları',
          channelDescription:
              'Fiyat düşüşleri, doğrulamalar ve radar sinyalleri.',
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
      );
      await _localNotifications.show(
        DateTime.now().millisecondsSinceEpoch ~/ 1000,
        title,
        body,
        details,
      );
    } catch (e) {
      debugPrint('Local notification show failed: $e');
    }
  }

  Future<void> _syncTokenForUser(String uid) async {
    try {
      final token = await _messaging.getToken();
      if (token == null || token.isEmpty) {
        debugPrint('FCM_TOKEN_RECEIVED: null/empty — token alınamadı');
        return;
      }
      debugPrint('FCM_TOKEN_RECEIVED');
      await _writeToken(uid: uid, token: token);
    } catch (e) {
      debugPrint('FCM token sync failed: $e');
    }
  }

  Future<void> _writeToken({required String uid, required String token}) async {
    if (_lastWrittenToken == token) return;
    debugPrint('FCM_TOKEN_SAVE_START');
    try {
      await _svc.userDoc(uid).set({
        'fcmToken': token,
      }, SetOptions(merge: true));
      _lastWrittenToken = token;
      debugPrint('FCM_TOKEN_SAVE_SUCCESS');
    } catch (e) {
      debugPrint('FCM_TOKEN_SAVE_FAILED: $e');
    }
  }

  /// Drops the token from Firestore and unsubscribes the device. Call this
  /// before sign-out so the old uid stops receiving push for this device.
  Future<void> clearTokenForCurrentUser() async {
    final uid = _activeUid;
    _lastWrittenToken = null;
    if (uid == null || uid.isEmpty) return;
    try {
      await _svc.userDoc(uid).set({
        'fcmToken': FieldValue.delete(),
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('FCM token clear failed: $e');
    }
    try {
      await _messaging.deleteToken();
    } catch (e) {
      debugPrint('FCM deleteToken failed: $e');
    }
  }

  Future<void> dispose() async {
    await _authSub?.cancel();
    await _tokenRefreshSub?.cancel();
    await _foregroundSub?.cancel();
    _authSub = null;
    _tokenRefreshSub = null;
    _foregroundSub = null;
    _initialized = false;
  }
}
