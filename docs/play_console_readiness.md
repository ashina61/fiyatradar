# FiyatRadar — Play Console Hazırlık Raporu

Tarih: 2026-05-14  
Sürüm: `1.0.1+3` (pubspec.yaml)  
Branch: `claude/neighborhood-market-system-lKpfD`

Bu rapor, Play Console internal track yüklemesi öncesi mevcut durumu özetler.
"Yapıldı" satırları, koda + manifest + gradle dosyalarına dayanır; "Yapılacak"
satırları Play Store yayını için bir blocker veya açık iyileştirme alanıdır.

---

## 1) Android build & paketleme

| Konu | Durum | Detay |
|---|---|---|
| `applicationId` | ✅ | `com.fiyatradar` (android/app/build.gradle) |
| `versionCode` / `versionName` | ⚠ | `local.properties`'ten okunuyor — CI'da set edilmesi şart |
| `minSdk` | ✅ | 23 (Android 6.0+; pazarın ~%95'i) |
| `targetSdk` | ✅ | 35 (Play 2025 minimum target karşılanıyor) |
| Release signing | ✅ | `key.properties` üzerinden yönlendirilmiş, `.gitignore`'da |
| ProGuard / R8 | ✅ | `minifyEnabled true`, `shrinkResources true` |
| `multiDex` | ✅ | açık |
| `usesCleartextTraffic` | ✅ | `false` |

**Yapılacak:** Release build alındığında `versionCode` mutlaka monoton artan
olmalı. Şimdiki taban: `1.0.1+3` ⇒ Play'e ilk yüklemede `versionCode=3`.

---

## 2) İzinler & gizlilik (Data Safety formu)

| İzin | Manifest | Kullanım | Form alanı |
|---|---|---|---|
| `INTERNET` | ✅ | Firebase, görsel CDN | Kaçınılmaz |
| `ACCESS_FINE_LOCATION` | ✅ | "Konumla doldur" — fiyat ekleme adımında il/ilçe çıkarımı | "Yaklaşık konum" (precise=false beyanı yapılabilir) |
| `ACCESS_COARSE_LOCATION` | ✅ | Aynı amaç, fallback | "Yaklaşık konum" |
| `ACCESS_BACKGROUND_LOCATION` | ❌ | İstemiyoruz | Beyan edilmez |
| `CAMERA` | ✅ | Raf fotoğrafı + barkod okutma | Görsel/foto |
| `POST_NOTIFICATIONS` | ✅ | Fiyat düşüş push | Push |
| `RECEIVE_BOOT_COMPLETED` | ✅ | Notification re-schedule | Push |
| `VIBRATE`, `WAKE_LOCK` | ✅ | Push UX | Push |
| `BILLING` | ✅ | FiyatRadar Pro (in_app_purchase) | Satın alma |

**Toplanan kişisel veri kategorileri** (Play "Data Safety" formu için):
- E-posta adresi (auth, opsiyonel olarak Google ile giriş)
- Ad ve kullanıcı adı
- Profil fotoğrafı (opsiyonel)
- Telefon numarası (opsiyonel)
- Konum: il/ilçe (yaklaşık)
- Uygulama içi etkileşim (puan, katkı, doğrulama oyu)
- Yorumlar (kullanıcı ürettiği içerik)
- Push token (Firebase Messaging)
- Crash/Analytics: Firebase Crashlytics + Analytics (debug'da kapalı, release'de açık)

**Veri paylaşımı:** Hiçbir kişisel veri 3. taraflarla paylaşılmıyor. (Firebase
backend dahili işleme sayılır; data-safety formunda "service provider"
olarak işaretlenir.)

**Yapıldı:** Kayıt sırasında KVKK + sözleşme onayı + 18+ beyanı versiyonlu
şekilde alınıyor (`_kConsentVersion = '2026.05'`). Onay zamanı
`users/{uid}.consents.acceptedAt` ve `users/{uid}.ageConfirmedAt` olarak
yazılıyor (bu PR ile eklendi).

---

## 3) Anlamlı kullanıcı sözleşmeleri & yasal sayfalar

| Sayfa | URL | Statü |
|---|---|---|
| Gizlilik Politikası | https://fiyatradar.netlify.app/gizlilik | ✅ canlı |
| Kullanıcı Sözleşmesi | https://fiyatradar.netlify.app/sozlesme | ✅ canlı |

**Yapılacak:** Play Console "Uygulama içeriği" bölümünde gizlilik politikası
URL'sinin doldurulması zorunlu.

---

## 4) Crash + Analytics

- `firebase_crashlytics: ^4.1.3` ve `firebase_analytics: ^11.3.3` ekli.
- `lib/main.dart` `setCrashlyticsCollectionEnabled(!kDebugMode)` ve
  `setAnalyticsCollectionEnabled(!kDebugMode)` çağırıyor; debug build'lerde
  veri akmıyor — bu, "developer should not test with prod data" Play kuralına
  uyumlu.
- `FlutterError.onError` ve `PlatformDispatcher.onError` Crashlytics'e
  yönlendiriliyor.

**Yapılacak:** Internal release alındıktan sonra Console "Crashes & ANRs"
sekmesinden ilk sinyalleri izlemek.

---

## 5) Play Billing (FiyatRadar Pro)

- `in_app_purchase: ^3.2.0` ekli.
- `com.android.vending.BILLING` izni manifest'te.
- Premium durumu **istemciye kapalı**: `firestore.rules` →
  `hasNoImmutableUserChanges` `isPremium`, `premiumUntil`, `premiumPlan`,
  `premiumProductId` alanlarını client write'tan koruyor. Yazma yalnız
  Cloud Function (Play Developer API webhook) üzerinden.

**Yapılacak:** Console → Monetization → In-app products tarafında
`fr_pro_monthly` ve `fr_pro_yearly` SKU'ları "Active" olmalı; license testers
listesine geliştirici e-postası eklenmeli.

---

## 6) Görsel varlıklar (Store listing assets)

Bu repodaki mevcut varlıklar:

| Asset | Yol | Boyut | Play Console gereksinimi |
|---|---|---|---|
| App icon | `assets/icons/icon.png` (288 KB) | 512×512 | ✅ |
| Adaptive foreground | `assets/images/fr_mark_foreground.png` | — | ✅ launcher_icons üretimi |
| Feature graphic | — | ❌ eksik | 1024×500 zorunlu — **yapılacak** |
| Phone screenshots | — | ❌ eksik | min. 2 (16:9 veya 9:16) — **yapılacak** |
| Tablet screenshots (opsiyonel) | — | ❌ eksik | Lite UX için skip edilebilir |

**Yapılacak:**  
- `assets/play_store/` altında 1024×500 feature graphic + 4-8 telefon ekran
  görüntüsü oluştur.  
- Console → Main store listing → Graphics bölümüne yükle.

---

## 7) Bu sürümde eklenen Play Console etkileri

| Değişiklik | Etki |
|---|---|
| `store_places.marketDays` alanı (mahalle pazarı günleri) | Sadece veri şeması; Play tarafında etki yok |
| Yorumlarda denormalize `authorAvatar` / `authorIsPro` | Yeni alanlar; data-safety formunda "user profile" kategorisi zaten kapsıyor |
| `usernameChangedAt` + 90 günlük cooldown | Şikayet riskini azaltır (kullanıcı isim spam'i) |
| `ageConfirmedAt` timestamp | Data-safety formunda "age confirmation collected" alanını işaretle |
| Image cacheHeight + frameBuilder | Algılanan performansı artırır — Play Vitals "slow rendering" metriklerine olumlu |
| **E-posta doğrulama zorunluluğu** | E-posta/şifre ile kayıt olan kullanıcı, fiyat ekleme / yorum / profil fotoğrafı / fiyat alarmı / katkı puanı gibi aksiyonları yapabilmek için Firebase verification mailindeki linke tıklamalı. Google ile gelen hesaplar zaten verified. Play Console **test hesabı** kayıt sonrası verification mailini açıp doğrulamış olmalı — aksi halde reviewer fiyat ekleyemez ve uygulama "boş" görünür. |

---

## 8) Yayın öncesi son blocker'lar

1. **Feature graphic + screenshot eksikliği** — store listing reddedilir.
2. **Firestore rules deploy** — bu PR `firestore.rules` ve `firestore.indexes.json`'i değiştirebilir; `firebase deploy --only firestore` yapılmadan internal release yayına alınmamalı.
3. **`google-services.json`** — CI/runner'da olmalı; repoda yok.
4. **Cihaz testi** — `flutter build appbundle --release` sonrası en az bir fiziksel cihazda smoke test (login → fiyat ekle → pazar seç → yorum yap).

---

## 9) Önerilen Console adımları (sırayla)

1. App bundle build: `flutter build appbundle --release`
2. Console → Production → Internal testing → Create release
3. Bundle yükle, release notes:  
   _"FiyatRadar 1.0.1 — mahalle pazarı katkı akışı, FiyatRadar Pro rozetleri, profil iyileştirmeleri."_
4. Internal testers e-posta listesini ekle (2-5 kişi yeterli)
5. Crashlytics + Analytics ilk sinyalleri 24-48 saat izle
6. Sonra Production'a promote
