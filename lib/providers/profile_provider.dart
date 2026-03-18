import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/user_model.dart';
import 'auth_provider.dart';

final profileProvider = StateNotifierProvider<ProfileNotifier, AsyncValue<UserModel?>>((ref) {
  return ProfileNotifier(ref);
});

class ProfileNotifier extends StateNotifier<AsyncValue<UserModel?>> {
  ProfileNotifier(this._ref) : super(const AsyncValue.data(null)) {
    _ref.listen<AsyncValue<UserModel?>>(userModelStreamProvider, (previous, next) {
      next.whenData((user) {
        state = AsyncValue.data(user);
        _ref.read(authNotifierProvider.notifier).setCurrentUser(user);
      });
    }, fireImmediately: true);

    _ref.listen<AsyncValue<User?>>(authStateProvider, (previous, next) {
      if (next.valueOrNull == null) {
        state = const AsyncValue.data(null);
        _ref.read(authNotifierProvider.notifier).setCurrentUser(null);
      }
    }, fireImmediately: true);
  }

  final Ref _ref;
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<void> loadProfile({String? uid}) async {
    try {
      final resolvedUid = uid ?? _auth.currentUser?.uid;
      if (resolvedUid == null) {
        state = const AsyncValue.data(null);
        _ref.read(authNotifierProvider.notifier).setCurrentUser(null);
        return;
      }

      state = const AsyncValue.loading();
      final doc = await _db.collection('users').doc(resolvedUid).get();
      if (doc.exists && doc.data() != null) {
        final user = UserModel.fromFirestore(doc);
        state = AsyncData(user);
        _ref.read(authNotifierProvider.notifier).setCurrentUser(user);
      } else {
        state = const AsyncData(null);
        _ref.read(authNotifierProvider.notifier).setCurrentUser(null);
      }
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  Future<bool> updateProfile(UserModel updatedUser) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return false;

    try {
      await _db.collection('users').doc(uid).set(updatedUser.toFirestore(), SetOptions(merge: true));
      state = AsyncData(updatedUser);
      _ref.read(authNotifierProvider.notifier).setCurrentUser(updatedUser);
      _ref.invalidate(userModelStreamProvider);
      return true;
    } catch (e) {
      // ignore: avoid_print
      print('Firebase yazma hatası: $e');
      return false;
    }
  }

  Future<bool> updateUsername({
    required UserModel currentUser,
    required String username,
    required Timestamp lastUsernameChange,
  }) async {
    final normalizedUsername = username.trim().toLowerCase();
    final updatedUser = currentUser.copyWith(
      username: normalizedUsername,
      lastUsernameChange: lastUsernameChange,
    );
    return updateProfile(updatedUser);
  }

  Future<bool> updatePasswordRenewalPeriod(int periodInMonths) async {
    final currentUser = state.valueOrNull;
    final uid = _auth.currentUser?.uid;
    if (uid == null || currentUser == null) return false;

    try {
      await _db.collection('users').doc(uid).set({
        'passwordRenewalPeriod': periodInMonths,
      }, SetOptions(merge: true));

      final updatedUser = currentUser.copyWith(passwordRenewalPeriod: periodInMonths);
      state = AsyncData(updatedUser);
      _ref.read(authNotifierProvider.notifier).setCurrentUser(updatedUser);
      _ref.invalidate(userModelStreamProvider);
      return true;
    } catch (e) {
      // ignore: avoid_print
      print('Şifre yenileme periyodu kaydedilemedi: $e');
      return false;
    }
  }
}
