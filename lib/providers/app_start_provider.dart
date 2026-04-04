import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'auth_provider.dart';
import 'firebase_init_provider.dart';

enum AppStartState { loading, login, authenticated }

final appStartStateProvider = Provider<AppStartState>((ref) {
  final firebaseReady = ref.watch(firebaseInitializedProvider);
  if (!firebaseReady) {
    return AppStartState.login;
  }

  final authAsync = ref.watch(authStateProvider);
  return authAsync.when(
    data: (user) => user == null ? AppStartState.login : AppStartState.authenticated,
    loading: () => AppStartState.loading,
    error: (_, __) => AppStartState.login,
  );
});
