import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fiyatradar/providers/firebase_init_provider.dart';

void main() {
  tearDown(() {
    firebaseInitialized = false;
  });

  test('firebaseInitialized getter/setter keeps notifier and provider in sync', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    expect(firebaseInitialized, isFalse);
    expect(container.read(firebaseInitializedProvider), isFalse);

    firebaseInitialized = true;

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

    firebaseInitialized = true;
    firebaseInitialized = false;

    expect(observed, [false, true, false]);
  });
}
