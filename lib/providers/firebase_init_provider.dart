import 'package:flutter_riverpod/flutter_riverpod.dart';

bool _firebaseInitialized = false;

final firebaseInitializedProvider = Provider<bool>((ref) {
  return _firebaseInitialized;
});

bool get firebaseInitialized => _firebaseInitialized;

set firebaseInitialized(bool value) {
  _firebaseInitialized = value;
}
