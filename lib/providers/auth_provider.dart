import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'firebase_init_provider.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';

final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService();
});

final authStateProvider = StreamProvider<User?>((ref) {
  if (!ref.watch(firebaseInitializedProvider)) return Stream.value(null);
  return ref.watch(authServiceProvider).authStateChanges;
});

final authUidProvider = Provider<String?>((ref) {
  return ref.watch(authStateProvider).valueOrNull?.uid;
});

final currentUserProvider = Provider<AsyncValue<UserModel?>>((ref) {
  return ref.watch(userModelStreamProvider);
});

final userModelStreamProvider = StreamProvider<UserModel?>((ref) {
  if (!ref.watch(firebaseInitializedProvider)) return Stream.value(null);

  final user = ref.watch(authStateProvider).valueOrNull;
  if (user == null) {
    return Stream.value(null);
  }

  return ref
      .watch(authServiceProvider)
      .watchUserModel(user.uid);
});

class AuthNotifier extends StateNotifier<AsyncValue<UserModel?>> {
  final AuthService _authService;

  AuthNotifier(this._authService) : super(const AsyncValue.loading());

  Future<void> signIn({
    required String email,
    required String password,
  }) async {
    state = const AsyncValue.loading();
    try {
      final user = await _authService.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      state = AsyncValue.data(user);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> register({
    required String email,
    required String password,
    required String name,
  }) async {
    state = const AsyncValue.loading();
    try {
      final user = await _authService.registerWithEmailAndPassword(
        email: email,
        password: password,
        name: name,
      );
      state = AsyncValue.data(user);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> signOut() async {
    await _authService.signOut();
    state = const AsyncValue.data(null);
  }

  Future<void> resetPassword(String email) async {
    await _authService.resetPassword(email);
  }

  Future<void> makeAdmin() async {
    final currentUser = _authService.currentUser;
    if (currentUser != null) {
      await _authService.makeAdmin(currentUser.uid);
    }
  }

  Future<void> refreshCurrentUser() async {
    final currentUser = _authService.currentUser;
    if (currentUser == null) {
      state = const AsyncValue.data(null);
      return;
    }

    state = AsyncValue.data(await _authService.getUserModel(currentUser.uid));
  }

  void setCurrentUser(UserModel? user) {
    state = AsyncValue.data(user);
  }
}

final authNotifierProvider =
    StateNotifierProvider<AuthNotifier, AsyncValue<UserModel?>>((ref) {
  return AuthNotifier(ref.watch(authServiceProvider));
});
