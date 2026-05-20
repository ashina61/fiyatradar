import 'package:flutter/foundation.dart';

/// Tek noktadan AdMob ad unit id çözümü.
///
/// Debug build'lerde her zaman Google'ın resmi test id'sini döner —
/// gerçek impression sayılmaz, hesap risk almaz. Release build'de
/// `--dart-define=ADMOB_BANNER_ANDROID=...` ile override edilebilir;
/// verilmezse hard-coded production id fallback'i kullanılır.
///
/// iOS şu an hedefte değil — yalnızca Android.
class AdHelper {
  AdHelper._();

  static String get bannerAdUnitId {
    if (kDebugMode) {
      // Google resmi test banner — https://developers.google.com/admob/android/test-ads
      return 'ca-app-pub-3940256099942544/6300978111';
    }
    return const String.fromEnvironment(
      'ADMOB_BANNER_ANDROID',
      defaultValue: 'ca-app-pub-7857385959432819/3388882563',
    );
  }
}
