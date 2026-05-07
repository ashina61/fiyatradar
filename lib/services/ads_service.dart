import 'package:flutter/foundation.dart';

/// Reklam servisi iskeleti.
///
/// Üretimde `google_mobile_ads` paketi eklendiğinde gerçek implementation
/// buraya gelir. Şu an no-op — `AdBanner` widget Pro değilse "TODO ad slot"
/// placeholder gösterir, Pro ise hiç render etmez. Bu sayede:
///   1. Pubspec ek bağımlılık yok (Play Console AdMob app id ihtiyacı yok).
///   2. UI tarafı şimdiden ad-aware: Pro abone reklam görmez.
///   3. SDK eklendiğinde sadece bu dosya doldurulur, çağrı noktaları değişmez.
///
/// Üretim setup checklist (Aşama 3 backlog):
///   • pubspec.yaml: google_mobile_ads: ^5.x.x
///   • android/app/src/main/AndroidManifest.xml application içinde:
///     <meta-data android:name="com.google.android.gms.ads.APPLICATION_ID"
///                android:value="ca-app-pub-XXXXXXXXXXXXXXXX~XXXXXXXXXX"/>
///   • ios/Runner/Info.plist'e GADApplicationIdentifier
///   • main.dart: MobileAds.instance.initialize();
///   • AdsService.instance.init() → preload banner + interstitial
class AdsService {
  AdsService._();
  static final AdsService instance = AdsService._();

  bool _initialized = false;
  bool get initialized => _initialized;

  /// Şu anki implementation no-op. Üretim implementation'ı:
  ///   • google_mobile_ads.MobileAds.instance.initialize()
  ///   • test device id'leri release-only debug ile filtrele
  Future<void> init() async {
    if (_initialized) return;
    _initialized = true;
    if (kDebugMode) {
      debugPrint('AdsService: stub init() — google_mobile_ads not wired yet.');
    }
  }
}
