import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

/// FiyatRadar AdMob entegrasyonu.
///
/// Tasarım kararları:
///   • Pro kullanıcı asla reklam görmez — gating widget seviyesinde
///     (`FRAdSlot.isPremium`, `FRInlineBannerAd.isPremium`). Service yine
///     de Pro durumdan habersiz; çağrı noktası check ediyor.
///   • Bütün ad unit id'leri burada toplandı; production'da AdMob
///     console'dan alınan id'lerle `_prodAndroidBanner` vs. doldurulur.
///   • Beta/debug build'lerde Google'ın resmi test id'leri kullanılıyor —
///     gerçek reklam yüklenmez, false impression sayılmaz.
///
/// Production checklist:
///   1. AdMob console'da app + ad unit'leri oluştur.
///   2. AndroidManifest meta-data APPLICATION_ID gerçek id ile değiştir.
///   3. iOS Info.plist GADApplicationIdentifier'ı ekle.
///   4. `_prodAndroidBanner` vb. değerleri doldur; `_useTestIds` otomatik
///      false döner çünkü id artık boş değil.
class AdsService {
  AdsService._();
  static final AdsService instance = AdsService._();

  bool _initialized = false;
  bool get initialized => _initialized;

  // ─── Ad unit id tablosu ──────────────────────────────────────────────
  // Test id'leri Google'ın resmi sandbox değerleri:
  // https://developers.google.com/admob/android/test-ads
  static const String _testAndroidBanner =
      'ca-app-pub-3940256099942544/6300978111';
  static const String _testIosBanner =
      'ca-app-pub-3940256099942544/2934735716';
  static const String _testAndroidInterstitial =
      'ca-app-pub-3940256099942544/1033173712';
  static const String _testIosInterstitial =
      'ca-app-pub-3940256099942544/4411468910';

  // TODO(prod): AdMob console'dan al ve doldur. Boş olduğu sürece
  // _useTestIds true döner; production'a geçişte buraya gerçek id yaz.
  static const String _prodAndroidBanner = '';
  static const String _prodIosBanner = '';
  static const String _prodAndroidInterstitial = '';
  static const String _prodIosInterstitial = '';

  /// Beta + production-id-yok durumlarında test reklamı yükle.
  bool get _useTestIds => kDebugMode || _prodAndroidBanner.isEmpty;

  String get bannerAdUnitId {
    if (Platform.isAndroid) {
      return _useTestIds ? _testAndroidBanner : _prodAndroidBanner;
    }
    if (Platform.isIOS) {
      return _useTestIds ? _testIosBanner : _prodIosBanner;
    }
    return _testAndroidBanner;
  }

  String get interstitialAdUnitId {
    if (Platform.isAndroid) {
      return _useTestIds ? _testAndroidInterstitial : _prodAndroidInterstitial;
    }
    if (Platform.isIOS) {
      return _useTestIds ? _testIosInterstitial : _prodIosInterstitial;
    }
    return _testAndroidInterstitial;
  }

  Future<void> init() async {
    if (_initialized) return;
    try {
      await MobileAds.instance.initialize();
      _initialized = true;
      if (kDebugMode) {
        debugPrint('AdsService: MobileAds initialized (testIds=$_useTestIds).');
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
