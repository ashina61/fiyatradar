import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../core/ads/ad_helper.dart';

/// FiyatRadar AdMob entegrasyonu.
///
/// Tasarım kararları:
///   • Pro kullanıcı asla reklam görmez — gating widget seviyesinde
///     (`FRAdSlot.isPremium`, `FRInlineBannerAd.isPremium`). Service yine
///     de Pro durumdan habersiz; çağrı noktası check ediyor.
///   • Banner ve interstitial ad unit id'leri tek noktadan `AdHelper`
///     üzerinden çözülüyor: debug → Google resmi test id, release →
///     `--dart-define=ADMOB_BANNER_ANDROID` / `ADMOB_INTERSTITIAL_ANDROID`
///     ile override + production fallback.
///   • Init sırası `main.dart`'ta: Firebase → ConsentManager (UMP) →
///     MobileAds.initialize → runApp. Bu service `init()` tekrar
///     `MobileAds.initialize()` çağrısı yapsa da SDK idempotent.
class AdsService {
  AdsService._();
  static final AdsService instance = AdsService._();

  bool _initialized = false;
  bool get initialized => _initialized;

  String get bannerAdUnitId => AdHelper.bannerAdUnitId;

  String get interstitialAdUnitId => AdHelper.interstitialAdUnitId;

  Future<void> init() async {
    if (_initialized) return;
    try {
      await MobileAds.instance.initialize();
      _initialized = true;
      if (kDebugMode) {
        debugPrint(
          'AdsService: MobileAds initialized '
          '(banner=${AdHelper.bannerAdUnitId}, '
          'interstitial=${AdHelper.interstitialAdUnitId}).',
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
