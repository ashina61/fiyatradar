import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

import 'firebase_service.dart';

/// Wires `firebase_messaging` to the Firestore-backed notification system the
/// Cloud Function (`functions/index.js → onProductPriceDrop`) already targets.
///
/// Responsibilities:
///   • Request runtime permission (no-op on Android < 13 / iOS).
///   • Persist the device FCM token to `users/{uid}.fcmToken`.
///   • Refresh the token after auth changes and on `onTokenRefresh`.
///   • Forward foreground messages so the in-app notification list stays in
///     sync without waiting for the next snapshot from the user-doc stream.
class MessagingService {
  MessagingService._();
  static final MessagingService instance = MessagingService._();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FirebaseService _svc = FirebaseService.instance;

  StreamSubscription<String>? _tokenRefreshSub;
  StreamSubscription<RemoteMessage>? _foregroundSub;
  StreamSubscription<User?>? _authSub;

  String? _activeUid;
  String? _lastWrittenToken;
  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;
    _initialized = true;

    try {
      await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );
    } catch (e) {
      debugPrint('FCM requestPermission failed: $e');
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
      final uid = _activeUid;
      if (uid == null || uid.isEmpty) return;
      unawaited(_writeToken(uid: uid, token: token));
    });

    _foregroundSub = FirebaseMessaging.onMessage.listen((message) {
      // The Cloud Function already writes a `users/{uid}/notifications/{id}`
      // doc, which the in-app notification stream picks up. We just log here
      // so the foreground delivery is observable in debug builds.
      debugPrint(
        'FCM foreground: ${message.notification?.title} · ${message.data}',
      );
    });
  }

  Future<void> _syncTokenForUser(String uid) async {
    try {
      final token = await _messaging.getToken();
      if (token == null || token.isEmpty) return;
      await _writeToken(uid: uid, token: token);
    } catch (e) {
      debugPrint('FCM token sync failed: $e');
    }
  }

  Future<void> _writeToken({required String uid, required String token}) async {
    if (_lastWrittenToken == token) return;
    try {
      await _svc.userDoc(uid).set({
        'fcmToken': token,
      }, SetOptions(merge: true));
      _lastWrittenToken = token;
    } catch (e) {
      debugPrint('FCM token write failed: $e');
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
