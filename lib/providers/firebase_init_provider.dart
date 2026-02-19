import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class FirebaseInitializedState extends ChangeNotifier {
  FirebaseInitializedState([this._value = false]);

  bool _value;

  bool get value => _value;

  set value(bool next) {
    if (_value == next) return;
    _value = next;
    notifyListeners();
  }
}

final firebaseInitializedNotifier = FirebaseInitializedState();

final firebaseInitializedStateProvider =
    ChangeNotifierProvider<FirebaseInitializedState>((ref) {
  return firebaseInitializedNotifier;
});

final firebaseInitializedProvider = Provider<bool>((ref) {
  return ref.watch(firebaseInitializedStateProvider).value;
});

bool get firebaseInitialized => firebaseInitializedNotifier.value;

set firebaseInitialized(bool value) {
  firebaseInitializedNotifier.value = value;
}
