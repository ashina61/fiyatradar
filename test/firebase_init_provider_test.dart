import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fiyatradar/providers/firebase_init_provider.dart';

void main() {
  tearDown(() {
    firebaseInitializedNotifier.value = false;
  });

  test('firebaseInitialized notifier and provider stay in sync', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    expect(firebaseInitializedNotifier.value, isFalse);
    expect(container.read(firebaseInitializedProvider), isFalse);

    firebaseInitializedNotifier.value = true;

    expect(firebaseInitializedNotifier.value, isTrue);
    expect(container.read(firebaseInitializedProvider), isTrue);
  });

  test('provider reacts to notifier changes', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final observed = <bool>[];
    final sub = container.listen<bool>(
      firebaseInitializedProvider,
      (previous, next) => observed.add(next),
      fireImmediately: true,
    );
    addTearDown(sub.close);

    firebaseInitializedNotifier.value = true;
    firebaseInitializedNotifier.value = false;

    expect(observed, [false, true, false]);
  });
}
