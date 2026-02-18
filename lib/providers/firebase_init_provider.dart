import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final firebaseInitializedListenableProvider = ValueListenableProvider<bool>(
  (ref) => firebaseInitializedNotifier,
);

final firebaseInitializedProvider = Provider<bool>((ref) {
  return ref.watch(firebaseInitializedListenableProvider);
});

final ValueNotifier<bool> firebaseInitializedNotifier = ValueNotifier(false);

bool get firebaseInitialized => firebaseInitializedNotifier.value;

set firebaseInitialized(bool value) {
  firebaseInitializedNotifier.value = value;
}
