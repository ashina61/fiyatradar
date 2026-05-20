import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

/// Google UMP (User Messaging Platform) consent akışı.
///
/// `MobileAds.instance.initialize()`'tan ÖNCE çağrılmalı — EEA/UK
/// kullanıcılarına consent formu göstererek GDPR/IAB TCF uyumluluğu
/// sağlar. Hata durumunda app'i bloklamaz, sessizce devam eder
/// (consent yoksa kişiselleştirilmemiş reklam serve edilir).
class ConsentManager {
  ConsentManager._();
  static final ConsentManager instance = ConsentManager._();

  Future<void> gatherConsent() async {
    final completer = Completer<void>();
    final params = ConsentRequestParameters();

    void finish() {
      if (!completer.isCompleted) completer.complete();
    }

    ConsentInformation.instance.requestConsentInfoUpdate(
      params,
      () {
        // Status taze; form gerekiyorsa yükle + göster, değilse devam et.
        ConsentForm.loadAndShowConsentFormIfRequired((FormError? error) {
          if (error != null && kDebugMode) {
            debugPrint(
              'ConsentForm.loadAndShowConsentFormIfRequired error: '
              '${error.errorCode} ${error.message}',
            );
          }
          finish();
        });
      },
      (FormError error) {
        if (kDebugMode) {
          debugPrint(
            'requestConsentInfoUpdate error: ${error.errorCode} ${error.message}',
          );
        }
        finish();
      },
    );

    return completer.future;
  }
}
