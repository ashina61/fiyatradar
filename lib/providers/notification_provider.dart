import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/notification_model.dart';
import '../services/notification_service.dart';
import '../services/firestore_service.dart';
import 'auth_provider.dart';
import 'firebase_init_provider.dart';
import 'product_provider.dart';

final _notificationOptimisticProvider =
    StateProvider<Map<String, bool>>((ref) => <String, bool>{});
final _notificationBootstrapCompletedUidsProvider =
    StateProvider<Set<String>>((ref) => <String>{});

final notificationBootstrapProvider = Provider<void>((ref) {
  if (!ref.watch(firebaseInitializedProvider)) return;
  final user = ref.watch(authStateProvider).valueOrNull;
  if (user == null) return;

  final completed = ref.watch(_notificationBootstrapCompletedUidsProvider);
  if (completed.contains(user.uid)) return;

  final service = NotificationService();
  unawaited(NotificationService.requestNotificationPermissions());
  unawaited(service.setupForegroundNotifications());
  service.setupNotificationOpenedApp();
  unawaited(
    service.getFCMToken().then((token) async {
      if (token == null || token.isEmpty) return;
      await ref.read(firestoreServiceProvider).updateUserFcmToken(user.uid, token);
    }),
  );

  ref.read(_notificationBootstrapCompletedUidsProvider.notifier).state = {
    ...completed,
    user.uid,
  };
});

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

final notificationsProvider = Provider<AsyncValue<List<NotificationItem>>>((ref) {
  final asyncList = ref.watch(notificationsStreamProvider);
  final optimistic = ref.watch(_notificationOptimisticProvider);

  return asyncList.whenData(
    (list) => list
        .map(
          (item) => optimistic.containsKey(item.id)
              ? item.copyWith(isRead: optimistic[item.id])
              : item,
        )
        .toList(growable: false),
  );
});

final unreadCountProvider = Provider<int>((ref) {
  final asyncList = ref.watch(notificationsProvider);
  return asyncList.maybeWhen(
    data: (list) => list.where((n) => !n.isRead).length,
    orElse: () => 0,
  );
});

final unreadNotificationCountProvider = unreadCountProvider;

class NotificationNotifier extends StateNotifier<AsyncValue<void>> {
  NotificationNotifier(this._firestoreService, this._ref)
      : super(const AsyncValue.data(null));

  final FirestoreService _firestoreService;
  final Ref _ref;

  Future<void> markAsRead(String notificationId) async {
    final user = _ref.read(authStateProvider).valueOrNull;
    if (user == null) return;

    final current = _ref.read(_notificationOptimisticProvider);
    _ref.read(_notificationOptimisticProvider.notifier).state = {
      ...current,
      notificationId: true,
    };

    try {
      await _firestoreService.markRead(user.uid, notificationId);
    } catch (_) {
      _ref.read(_notificationOptimisticProvider.notifier).state = current;
      rethrow;
    }
  }

  Future<void> markAllAsRead() async {
    final user = _ref.read(authStateProvider).valueOrNull;
    final notifications = _ref.read(notificationsProvider).valueOrNull;
    if (user == null || notifications == null) return;

    final current = _ref.read(_notificationOptimisticProvider);
    final optimistic = <String, bool>{...current};
    for (final item in notifications.where((item) => !item.isRead)) {
      optimistic[item.id] = true;
    }
    _ref.read(_notificationOptimisticProvider.notifier).state = optimistic;

    try {
      await _firestoreService.markAllNotificationsAsRead(user.uid);
    } catch (_) {
      _ref.read(_notificationOptimisticProvider.notifier).state = current;
      rethrow;
    }
  }

  Future<void> sendNotification({
    required String userId,
    required String type,
    required String title,
    required String message,
    String? productId,
    String? productName,
    String? imageUrl,
  }) async {
    final notification = NotificationItem(
      id: '',
      type: type,
      title: title,
      message: message,
      isRead: false,
      createdAt: Timestamp.now(),
      metaData: {
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
