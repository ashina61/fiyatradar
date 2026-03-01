import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/notification_model.dart';
import '../services/firestore_service.dart';
import 'auth_provider.dart';
import 'firebase_init_provider.dart';

final notificationsStreamProvider = StreamProvider<List<NotificationItem>>((ref) {
  if (!ref.watch(firebaseInitializedProvider)) {
    return Stream<List<NotificationItem>>.value(const <NotificationItem>[]);
  }

  final authState = ref.watch(authStateProvider);
  return authState.when(
    data: (user) {
      if (user == null) {
        return Stream<List<NotificationItem>>.value(const <NotificationItem>[]);
      }
      final firestore = ref.watch(firestoreServiceProvider);
      unawaited(firestore.migrateLegacyToInboxIfNeeded(user.uid));
      return firestore.getNotifications(user.uid);
    },
    loading: () => Stream<List<NotificationItem>>.value(const <NotificationItem>[]),
    error: (_, __) => Stream<List<NotificationItem>>.value(const <NotificationItem>[]),
  );
});

final notificationsProvider = notificationsStreamProvider;

final unreadCountProvider = Provider<int>((ref) {
  final asyncList = ref.watch(notificationsStreamProvider);
  return asyncList.maybeWhen(
    data: (list) => list.where((n) => !n.read).length,
    orElse: () => 0,
  );
});

final unreadNotificationCountProvider = unreadCountProvider;

class NotificationNotifier extends StateNotifier<AsyncValue<void>> {
  final FirestoreService _firestoreService;
  final Ref _ref;

  NotificationNotifier(this._firestoreService, this._ref)
      : super(const AsyncValue.data(null));

  Future<void> markAsRead(String notificationId) async {
    final authState = _ref.read(authStateProvider);
    final user = authState.valueOrNull;
    if (user == null) return;
    await _firestoreService.markRead(user.uid, notificationId);
  }

  Future<void> markAllAsRead() async {
    final authState = _ref.read(authStateProvider);
    authState.whenData((user) async {
      if (user != null) {
        await _firestoreService.markAllNotificationsAsRead(user.uid);
      }
    });
  }

  Future<void> sendNotification({
    required String userId,
    required NotificationType type,
    required String title,
    required String body,
    String? productId,
    String? productName,
    String? imageUrl,
  }) async {
    final notification = NotificationItem(
      id: '',
      source: NotificationSource.primary,
      type: type,
      title: title,
      body: body,
      createdAt: DateTime.now(),
      meta: {
        'userId': userId,
        if (productId != null) 'productId': productId,
        if (productName != null) 'productName': productName,
        if (imageUrl != null) 'imageUrl': imageUrl,
      },
    );

    await _firestoreService.addNotification(notification);
  }
}

final notificationNotifierProvider =
    StateNotifierProvider<NotificationNotifier, AsyncValue<void>>((ref) {
  return NotificationNotifier(ref.watch(firestoreServiceProvider), ref);
});

// Verification checklist for inbox live badge:
// 1) Add doc to users/{uid}/inbox => badge increments instantly.
// 2) Legacy docs exist only once then migrate to inbox on first watch.
// 3) Mark read in inbox => badge decrements instantly.
// 4) Navigate tabs back/forth => badge remains live.
// 5) Enable debug flag and verify [inbox] stream + migration logs.
