import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../core/ads/ad_helper.dart';

/// FiyatRadar AdMob entegrasyonu.
///
/// Tasarım kararları:
///   • Pro kullanıcı asla reklam görmez — gating widget seviyesinde
///     (`FRAdSlot.isPremium`, `FRInlineBannerAd.isPremium`). Service yine
///     de Pro durumdan habersiz; çağrı noktası check ediyor.
///   • Banner ad unit id `AdHelper.bannerAdUnitId` üzerinden çözülüyor:
///     debug → resmi test id, release → `--dart-define=ADMOB_BANNER_ANDROID`
///     ile override + production fallback.
///   • Interstitial henüz production'a açılmadı — debug/release fark
///     etmeksizin Google test id'siyle yükleniyor.
///   • Init sırası `main.dart`'ta: Firebase → ConsentManager (UMP) →
///     MobileAds.initialize → runApp. Bu service `init()` tekrar
///     `MobileAds.initialize()` çağrısı yapsa da SDK idempotent.
class AdsService {
  AdsService._();
  static final AdsService instance = AdsService._();

  bool _initialized = false;
  bool get initialized => _initialized;

  // ─── Ad unit id tablosu ──────────────────────────────────────────────
  // Banner id'leri tek noktadan AdHelper çözüyor (debug → test, release →
  // --dart-define override + production fallback). Interstitial henüz
  // production'a açılmadığı için lokal test id'leriyle çalışıyor.
  // https://developers.google.com/admob/android/test-ads
  static const String _testAndroidInterstitial =
      'ca-app-pub-3940256099942544/1033173712';
  static const String _testIosInterstitial =
      'ca-app-pub-3940256099942544/4411468910';

  String get bannerAdUnitId => AdHelper.bannerAdUnitId;

  String get interstitialAdUnitId {
    if (Platform.isIOS) return _testIosInterstitial;
    return _testAndroidInterstitial;
  }

  Future<void> init() async {
    if (_initialized) return;
    try {
      await MobileAds.instance.initialize();
      _initialized = true;
      if (kDebugMode) {
        debugPrint(
          'AdsService: MobileAds initialized '
          '(banner=${AdHelper.bannerAdUnitId}).',
        );
      }
      unawaited(preloadInterstitial());
    } catch (e, st) {
      // Reklam SDK init başarısız olsa bile uygulama akmaya devam etsin —
      // banner widget build sırasında load hatası "boş slot"a düşer.
      debugPrint('AdsService init failed: $e\n$st');
    }
  }

  // ─── Interstitial yönetimi ────────────────────────────────────────────
  // Cooldown'lu basit queue: 60 sn'den önce ikincisi gösterilmez.
  InterstitialAd? _pendingInterstitial;
  bool _loadingInterstitial = false;
  DateTime? _lastInterstitialShownAt;

  static const Duration _interstitialCooldown = Duration(seconds: 60);

  Future<void> preloadInterstitial() async {
    if (!_initialized || _pendingInterstitial != null || _loadingInterstitial) {
      return;
    }
    _loadingInterstitial = true;
    await InterstitialAd.load(
      adUnitId: interstitialAdUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _pendingInterstitial = ad;
          _loadingInterstitial = false;
        },
        onAdFailedToLoad: (err) {
          _pendingInterstitial = null;
          _loadingInterstitial = false;
          if (kDebugMode) {
            debugPrint('Interstitial load failed: ${err.message}');
          }
        },
      ),
    );
  }

  /// Pro değilse ve cooldown bittiyse interstitial gösterir.
  /// Çağrı noktası mutlaka Pro check'i yapmalı; service bunu bilmez.
  Future<void> maybeShowInterstitial() async {
    if (!_initialized) return;
    final now = DateTime.now();
    if (_lastInterstitialShownAt != null &&
        now.difference(_lastInterstitialShownAt!) < _interstitialCooldown) {
      return;
    }
    final ad = _pendingInterstitial;
    if (ad == null) {
      // Henüz yüklenmemiş — sıradakini hazırla, bu seferi atla.
      unawaited(preloadInterstitial());
      return;
    }
    _pendingInterstitial = null;
    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        unawaited(preloadInterstitial());
      },
      onAdFailedToShowFullScreenContent: (ad, err) {
        ad.dispose();
        unawaited(preloadInterstitial());
      },
    );
    _lastInterstitialShownAt = now;
    await ad.show();
  }
}
