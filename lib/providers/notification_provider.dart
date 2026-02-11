import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../main.dart';
import '../models/notification_model.dart';
import '../services/firestore_service.dart';
import 'auth_provider.dart';
import 'product_provider.dart';

final notificationsProvider = StreamProvider<List<NotificationModel>>((ref) {
  if (!firebaseInitialized) return Stream.value([]);
  final authState = ref.watch(authStateProvider);
  return authState.when(
    data: (user) {
      if (user != null) {
        return ref.watch(firestoreServiceProvider).getNotifications(user.uid);
      }
      return Stream.value([]);
    },
    loading: () => Stream.value([]),
    error: (_, __) => Stream.value([]),
  );
});

final unreadNotificationCountProvider = StreamProvider<int>((ref) {
  if (!firebaseInitialized) return Stream.value(0);
  final authState = ref.watch(authStateProvider);
  return authState.when(
    data: (user) {
      if (user != null) {
        return ref
            .watch(firestoreServiceProvider)
            .getUnreadNotificationCount(user.uid);
      }
      return Stream.value(0);
    },
    loading: () => Stream.value(0),
    error: (_, __) => Stream.value(0),
  );
});

class NotificationNotifier extends StateNotifier<AsyncValue<void>> {
  final FirestoreService _firestoreService;
  final Ref _ref;

  NotificationNotifier(this._firestoreService, this._ref)
      : super(const AsyncValue.data(null));

  Future<void> markAsRead(String notificationId) async {
    await _firestoreService.markNotificationAsRead(notificationId);
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
    final notification = NotificationModel(
      id: '',
      userId: userId,
      type: type,
      title: title,
      body: body,
      productId: productId,
      productName: productName,
      imageUrl: imageUrl,
      createdAt: DateTime.now(),
      data: null,
    );

    await _firestoreService.addNotification(notification);
  }
}

final notificationNotifierProvider =
    StateNotifierProvider<NotificationNotifier, AsyncValue<void>>((ref) {
  return NotificationNotifier(ref.watch(firestoreServiceProvider), ref);
});
