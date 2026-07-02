# FiyatRadar — Kapsamlı Kod İnceleme Raporu

**Tarih:** 2026-07-02
**Kapsam:** Tüm Flutter istemcisi (`lib/`), Firestore güvenlik kuralları (`firestore.rules`), Storage kuralları (`storage.rules`), Cloud Functions (`functions/index.js`), index tanımları, CI/CD workflow'ları, Android manifest ve asset'ler.
**Yöntem:** Manuel satır satır inceleme + kural/kod çapraz doğrulama. (Not: Bu ortamın ağ politikası Flutter SDK indirmesine izin vermediği için `flutter analyze` çalıştırılamadı; bulgular statik okumayla doğrulandı.)

---

## Özet Karne

| Alan | Durum |
|---|---|
| Mimari / oturum yönetimi | İyi — cold start restore akışı sağlam |
| Premium / IAP güvenliği | Çok iyi — sunucu doğrulamalı, client yazamıyor |
| Firestore kuralları | İyi niyetli ve detaylı, ama **5-6 somut açık/çelişki var** |
| Cloud Functions | Çalışır, ama **maliyet bombası** ve eksik fonksiyon var |
| KVKK / Play Store uyumu | **Kritik sorun: hesap silme gerçekte veri silmiyor** |
| Ölçeklenebilirlik | Orta — katalog ve bildirim mimarisi büyümede zorlanır |
| Test kapsamı | Zayıf — 24k satır koda karşılık 4 test dosyası |

---

## 1. KRİTİK BULGULAR (yayın öncesi mutlaka düzeltilmeli)

### K1. Hesap silme akışı kullanıcı verisini SİLMİYOR (KVKK + Play politikası ihlali)
**Yer:** `lib/screens/profile_screens.dart:2176` (`_deleteAccount`) + `firestore.rules:368`

- `_deleteAccount` önce `userDoc(uid).delete()` çağırıyor, ama `firestore.rules` içinde `users/{uid}` için `allow delete: if isAdmin();` — yani **kullanıcı kendi dokümanını silemez, çağrı her zaman permission-denied olur**. Hata `try { } catch (_) {}` ile sessizce yutuluyor.
- Sonuç: Auth hesabı silinir ama Firestore'da **ad, telefon numarası, şehir/ilçe, favoriler, sepet, fcmToken ve tüm `notifications` alt koleksiyonu sonsuza kadar kalır**. Onay diyaloğundaki "profil bilgilerin kalıcı olarak silinir" ifadesi gerçeği yansıtmıyor. Bu hem KVKK hem Google Play "hesap silme" politikası açısından risk.
- İkincil hata: `releaseUsername` **auth silme işleminden önce** çalışıyor. `user.delete()` `requires-recent-login` ile başarısız olursa kullanıcının username rezervasyonu serbest kalmış olur — hesabı silinmemiş kullanıcının kullanıcı adını başkası kapabilir.

**Önerilen çözüm:** Hesap silmeyi bir Cloud Function'a taşı (`onCall` → Admin SDK ile user doc + alt koleksiyonlar + Storage dosyaları + username rezervasyonu + auth hesabını tek yerden sil). Client'ta sıralamayı düzelt; en azından rules'a `allow delete: if isAdmin() || isOwner(uid)` ekle ve alt koleksiyonları da temizle.

### K2. E-posta doğrulaması sonrası ID token yenilenmiyor → yeni doğrulanan kullanıcı ~1 saat katkı yapamaz
**Yer:** `lib/state/app_state.dart:312` (`reloadAndCheckVerification`), `lib/screens/verify_email_screen.dart`

- Firestore/Storage kuralları `request.auth.token.email_verified` claim'ine bakıyor. `user.reload()` yalnızca client-side `emailVerified` bayrağını tazeler; **ID token'daki claim, token yenilenene kadar (1 saate kadar) `false` kalır**.
- Kodda hiçbir yerde doğrulama sonrası `getIdToken(true)` çağrısı yok (tek `getIdToken(true)` profil foto upload'ında var).
- Sonuç: Kullanıcı maildeki linke tıklar, "Doğruladım" der, uygulama onu içeri alır (client `emailVerified=true` görür) ama **fiyat ekleme, yorum, alarm, doğrulama oyu — hepsi `isVerified()` kuralına takılıp permission-denied olur**. Kullanıcı için "uygulama bozuk" hissi; üstelik `reloadAndCheckVerification` içindeki `emailVerified` doc yazımı da aynı sebeple sessizce başarısız oluyor.

**Çözüm:** Doğrulama başarılı olduğunda `await fresh.getIdToken(true);` ekle (VerifyEmailScreen akışı + AccountScreen `_refreshStatus`).

### K3. Yorum beğeni butonu üretimde tamamen kırık
**Yer:** `lib/state/app_state.dart:2339` (`toggleCommentLike`), `lib/screens/widgets/product_comments_section.dart:224`, `firestore.rules:941-956`

- UI'da beğeni butonu var ve `toggleCommentLike` `likedBy` + `likes` alanlarını yazıyor. Ama `comments` update kuralı değişebilir alanları `['text','updatedAt','authorName','authorAvatar','authorIsPro','authorTrustPercent']` ile sınırlıyor — `likes`/`likedBy` listede yok.
- Sonuç: **Admin dışında hiç kimse (yorum sahibi dahil) hiçbir yorumu beğenemez** — her tıklama permission-denied. Kodda "rules genişleyene kadar" notu var ama buton kullanıcıya açık durumda.

**Çözüm:** Ya kurala güvenli bir like-toggle istisnası ekle (sadece `likes`/`likedBy`/`updatedAt` değişimi + `likes == likedBy.size()` + kendi uid'ini ekleme/çıkarma), ya da butonu UI'dan kaldır.

### K4. `priceGroups` fiyatları herhangi bir doğrulanmış kullanıcı tarafından manipüle edilebilir
**Yer:** `firestore.rules:849-869`

- Update kuralı sayaçları (+1 monotonik) ve kimlik alanlarını koruyor, ama `latestPrice`, `trustedPrice`, `avgPrice`, `minPrice`, `maxPrice` için **yalnız tip kontrolü** var. Doğrulanmış herhangi bir hesap, herhangi bir bölgedeki herhangi bir ürünün ekranda gösterilen fiyatını tek update ile `0.01` ya da `9999` yapabilir.
- Bu, uygulamanın ana değer önerisini (güvenilir topluluk fiyatı) hedef alan en gerçekçi saldırı. Kuraldaki yorum da bunu kabul edip Cloud Function'a taşınmasını "TODO: P1" olarak işaretlemiş.

**Çözüm:** Aggregation'ı `onDocumentCreated('priceReports/...')` tetikleyicili bir Cloud Function'a taşı; `priceGroups` client yazımını tamamen kapat. (Bu aynı zamanda K5'i de çözer.)

### K5. Admin "priceGroup reset" özelliği kendi kuralına takılıyor — her zaman başarısız
**Yer:** `lib/state/app_state.dart:2115` (`adminResetPriceGroupAggregates`), `firestore.rules:858`

- `priceGroups` update kuralında `isAdmin()` bypass'ı **yok**; kural `verifiedCount`'un azalmasına izin vermiyor. Admin client `verifiedCount: 0` yazmaya çalıştığında **her zaman permission-denied** alır. Kodun kendi yorumu bile bunu itiraf ediyor ("admin client için aynı rule altında bu reset DENIED olur") ama özellik UI'da duruyor.
- Ek olarak reset payload'ı `hasSafePriceGroupPayload` gereği `lastReporterId == auth.uid` yazmak zorunda; bu da grubun "son raporlayan" verisini bozar.

**Çözüm:** Reset'i admin Cloud Function'a taşı veya kurala `isAdmin() ||` ekle.

### K6. Yeni kullanıcı, hesabını sahte gamification verisiyle doğabilir
**Yer:** `firestore.rules:211-222` (`hasSafeUserCreateDefaults`)

- Create kuralı `points`, `trust*` sayaçlarını 0'a zorluyor ama **`contributions`, `verifyContributions`, `photoContributions`, `currentStreak`, `longestStreak`, `badges` alanlarını kontrol etmiyor**. Kötü niyetli yeni hesap ilk create'te `contributions: 999999, currentStreak: 9999, badges: [tümü]` yazabilir.
- Ayrıca update tarafında `currentStreak`/`longestStreak` için delta cap yok (`gamification.dart:230`'daki TODO) — mevcut kullanıcı da streak'ini tek update ile istediği değere çekebilir.
- Etki: rozet/seviye/streak gösterimleri ve topluluk güven algısı kirletilebilir (liderlik tablosu `priceReports` aggregate'inden geldiği için puan tablosu etkilenmez, ama profil/rozet vitrini yalan söyler).

**Çözüm:** Create kuralına bu alanlar için `== 0` / boş liste şartı ekle; update'te streak alanlarına da `+1` cap koy.

### K7. Gizlilik: her giriş yapan kullanıcı (anonim dahil) TÜM kullanıcı profillerini okuyabilir
**Yer:** `firestore.rules:346` (`allow read: if signedIn();`)

- `users/{uid}` dokümanında **telefon numarası**, ad, şehir/ilçe, favoriler, sepet, `fcmToken`, bildirim tercihleri var. Anonim bir oturum açan herkes, uid'leri (yorumlarda, priceReports listelerinde açıkça geziyor) toplayıp bu profilleri okuyabilir.
- Telefon numarasının bu şekilde sızması KVKK açısından ciddi risk.

**Çözüm:** Kuralı `isOwner(uid) || isAdmin()`'e daralt. Başka kullanıcıların görmesi gereken alanlar (görünen ad, avatar, rozet) zaten yorum/rapor doc'larına denormalize ediliyor — gerekiyorsa ayrı bir `public_profiles/{uid}` koleksiyonu aç.

---

## 2. YÜKSEK ÖNCELİKLİ BULGULAR

### Y1. Cloud Functions maliyet bombası: her fiyat raporunda tüm `productAlerts` koleksiyonu taranabiliyor
**Yer:** `functions/index.js:597-607` (`onPriceGroupUpdate`)

- Indexed sorgu **başarılı olup 0 sonuç dönse bile** kod `collectionGroup('productAlerts').get()` ile TÜM alarm dokümanlarını çekiyor ("legacy fallback"). Alarm kurulmamış bir ürüne fiyat eklemek en yaygın senaryo → **her fiyat raporu tam koleksiyon taraması tetikliyor**. Kullanıcı ve alarm sayısı büyüdükçe Firestore okuma faturası ve function süresi doğrusal patlar.
- Aynı dosyada `onProductPriceDrop` da hata durumunda full-scan'e düşüyor (daha kabul edilebilir, ama aşağıdaki Y2 ile birleşince kalıcı hale geliyor).

**Çözüm:** 597-607 arasındaki "0 sonuçsa full scan" bloğunu tamamen kaldır; indexed sorguya güven.

### Y2. Deploy pipeline Firestore index'lerini HİÇ deploy etmiyor
**Yer:** `.github/workflows/firebase-deploy.yml`

- Step adı "Deploy Cloud Functions and Firestore rules/indexes" ama komut `--only functions,firestore:rules` — **`firestore:indexes` yok**. `firebase-functions-only-deploy.yml` de bilerek atlamış.
- Sonuç: `productAlerts` collection-group index'i prod'da yoksa Y1'deki scan fallback kalıcı çalışır. `functions/index.js:572`'deki yorum bu durumun gerçekten yaşandığını doğruluyor.

**Çözüm:** Komuta `firestore:indexes` ekle (veya tek seferlik `firebase deploy --only firestore:indexes` çalıştırıp pipeline'ı düzelt).

### Y3. Admin "bekleyen şubeler" ekranı için kompozit index eksik
**Yer:** `lib/state/app_state.dart:2140` (`watchAdminPendingStorePlaces`) + `firestore.indexes.json`

- Sorgu: `isActive == true` + `status == 'pending'` + `orderBy createdAt desc`. Index dosyasında `(isActive, status, updatedAt)` var ama **`(isActive, status, createdAt)` yok** → runtime'da FAILED_PRECONDITION; admin onay kuyruğu ekranı boş/hatalı düşer.

### Y4. `weeklyPremiumExpiryCheck` fonksiyonu yok ama kod ona güveniyor
**Yer:** `functions/index.js:1120` (yorum), export listesi

- `verifyPurchase` içindeki yorum "weeklyPremiumExpiryCheck zaten süreyi kullanarak hesap düşürür" diyor ama **böyle bir fonksiyon dosyada tanımlı değil**. Süresi dolan aboneliklerde `users/{uid}.isPremium` sonsuza kadar `true` kalır.
- Client `premium.isActive` getter'ı `premiumUntil`'e baktığı için UI gating çoğunlukla doğru çalışır; ama `premiumUntil` alanı herhangi bir sebeple null yazılmış eski kayıtlarda kullanıcı süresiz Pro kalır ve doc bazlı okuma yapan her yer (ör. `weeklySummary` bunu doğru kontrol ediyor, ileride yazılacak kod etmeyebilir) yanılır.

**Çözüm:** Haftalık scheduled function ekle: `isPremium == true && premiumUntil < now` olanları `isPremium=false` yap (yenileme kontrolü için Play API'ye de sorabilirsin).

### Y5. `weeklySummary` tüm kullanıcıları tarayıp kullanıcı başına sorgu atıyor (N+1)
**Yer:** `functions/index.js:1312`

- `db.collection('users').get()` + her kullanıcı için ayrı `priceReports` sorgusu. 10k kullanıcıda haftada ~10k+ sorgu; 100k'da timeout riski (varsayılan 60 sn / 540 sn sınırları). Kodun kendi yorumu da segment'leme öneriyor.
- **Çözüm:** Bölge başına tek sorgu atıp sonuçları memory'de kullanıcılara dağıt; kullanıcıları sayfalı işle; yalnız aktif kullanıcıları hedefle.

### Y6. Katalog mimarisi: `products.snapshots()` tüm koleksiyonu (priceHistory dahil) her istemciye indiriyor
**Yer:** `lib/state/app_state.dart:786`

- Limit yok. Her cold start + her ürün değişiminde **tüm katalog, 800 entry'e kadar büyüyebilen `priceHistory` array'leriyle** birlikte iner. Katalog 1-2 bin ürüne çıktığında açılış süresi, bellek ve Firestore okuma maliyeti ciddi biçimde büyür; her fiyat eklemesi tüm istemcilere tüm doc'u yeniden gönderir.
- `kEnableLegacyPriceHistoryMirror` false'a çekilip mirror kapatılsa bile mevcut history alanları inmeye devam eder.
- **Çözüm:** Aşama 3 planındaki mirror kaldırma işini önceliklendir; liste görünümleri için `priceHistory`'siz hafif ürün projeksiyonu (ayrı summary koleksiyonu veya alan silme migration'ı) kullan.

### Y7. `priceReports` koleksiyonunda iki farklı şema yaşıyor (şikayet + fiyat raporu)
**Yer:** `lib/state/app_state.dart:3452` (`reportPriceEntry`) vs `lib/services/price_report_service.dart` + `firestore.rules:739-794`

- "Fiyatı şikayet et" doc'ları (`createdByUid`, `entryId`, `status: active`) ile bölgesel fiyat raporları (`userId`, `groupId`, `localDateKey`) aynı koleksiyonda. Kurallar iki şemayı OR'layarak kabul etmek zorunda kalmış (karmaşık ve hataya açık), liderlik tablosu sorguları şikayet doc'larını da çekip client'ta eliyor (gereksiz okuma), `watchMyContributions` gibi sorgular alan adı ayrımına muhtaç.
- **Çözüm:** Şikayetleri `priceEntryReports` (veya mevcut `reports`) koleksiyonuna taşı; rules'ı sadeleştir.

### Y8. Tek `fcmToken` alanı: çok cihazlı kullanıcıda push kaybı
**Yer:** `lib/services/messaging_service.dart:245`

- Kullanıcı ikinci cihazda giriş yapınca token üzerine yazılır; ilk cihaz push alamaz. Çıkışta `clearTokenForCurrentUser` diğer cihazın token'ını da silebilir (aynı alan).
- **Çözüm:** `users/{uid}/fcmTokens/{token}` alt koleksiyonu veya token array'i + Cloud Functions'ta multicast.

### Y9. Yorum uzunluğu kuralları tutarsız + create'te limit yok
**Yer:** `firestore.rules:937` (create) vs `:954` (update), `app_state.dart:2290`

- Create kuralında `text` için hiç boyut sınırı yok (teoride ~1MB'lık yorum yazılabilir — client bypass'ı ile spam vektörü). Client 1000 karakter kabul ediyor; update kuralı 500 ile sınırlı → **501-1000 karakterlik yorum oluşturulabiliyor ama sonra düzenlenemiyor**.
- **Çözüm:** Create'e `text.size() <= 1000` ekle, update'i de 1000'e çek (veya her ikisini 500'de eşitle + client'ı 500'e çek).

---

## 3. ORTA / DÜŞÜK ÖNCELİKLİ BULGULAR

1. **`bootstrap()` seed'leri her açılışta çalışıyor** (`firebase_service.dart:712`): kullanıcı başına her boot'ta 4 gereksiz okuma + admin olmayanlar için başarısız yazma denemeleri. Seed işi tek seferlik admin script'e taşınmalı (`scripts/import_products_firestore.py` zaten var).
2. **`AppState` 3.800 satırlık god-class** — kodun kendi yorumu da kabul ediyor. `logout()` ve `refreshFromAuthSession()` içindeki ~40 satırlık teardown bloğu birebir kopya; tek `_teardown()` metoduna alınmalı (birinde alan unutulursa oturum sızıntısı olur).
3. **Splash her zaman açık tema** (`main.dart:428`): dark mode kullanıcısında açılışta beyaz flaş. `FRThemeController.instance.isDark`'a göre palet seç.
4. **Ölü/tehlikeli kod: `@Deprecated checkout()`** (`app_state.dart:3062`): `points`'i doğrudan set ediyor — puan düşüşünü rules zaten reddeder; ileride biri çağırırsa sessiz kırılır. Silinmeli.
5. **Kullanılmayan 760KB asset**: `assets/fiyatradar_marketler.json` (732K) + `fiyatradar_urunler.json` (28K) pubspec'te bundle'lanıyor ama `lib/` içinde hiç referans yok → APK şişkinliği.
6. **`hasOnlyCommentOwnerWritableKeys` fonksiyonu tanımlı ama kullanılmıyor** (`firestore.rules:259`) — update kuralı aynı listeyi inline tekrar ediyor. Ölü kural kodu kafa karıştırır.
7. **`watchProductComments` 100 doc çekip client-side sıralıyor** (`app_state.dart:2267`): `(productId, createdAt DESC)` index'i zaten `firestore.indexes.json`'da var — `orderBy` kullanılabilir, "missing index" gerekçesi geçersiz.
8. **`verify_email_screen` cooldown ticker'ı** her saniye `setState` çağırıyor; cooldown 0'a inince ticker iptal ediliyor mu kontrol edilmeli (küçük pil/CPU maliyeti).
9. **`AppState.init()` re-entrancy**: `_productsSub = ...` gibi atamalar null-check'siz; `_authSub` listener'ı `unawaited(init())` tetikleyebiliyor. `_initInProgress` çoğu yarışı kapatıyor ama `refreshFromAuthSession` ile eşzamanlı senaryoda çift subscription sızıntısı teorik olarak mümkün. Init'i tek bir `Future` alanı üzerinden idempotent yap.
10. **Şikayet raporları düzeltme sonrası tekrar açılamıyor** (`reportPriceEntry`): rapor `reviewed/removed` olduktan sonra kullanıcı aynı entry'yi bir daha raporlayamıyor (`'Tekrar raporlayamazsın'`). Fiyat tekrar bozulursa moderasyon sinyali kaybolur — bilinçli tasarımsa sorun değil, değilse doc id'ye tarih ekle.
11. **`adminApproveRequest` puan ödülü** (`app_state.dart:2465`): Admin başka kullanıcının doc'una `points: increment(25)` yazıyor — `isAdmin()` bypass'ı olduğu için çalışır, doğru. Ama bildirim `title/body` şeması `createUserNotification`'dan farklı (`type` alanı var, `read` alanı yok) → `AppNotification.fromDoc` `read` alanını nasıl okuyorsa tutarlılık kontrol edilmeli.
12. **`_awardContributionRewards` art arda birden çok `set` çağrısı** (rozet başına ayrı yazma + bildirim doc'ları): tek katkıda 4-6 ayrı Firestore round-trip. Batch'e alınabilir.
13. **Test kapsamı**: `basket_pricing_service`, `gamification`, `paywall`, smoke — toplam ~700 satır. AppState'in oy verme/puan/streak mantığı, Firestore rules senaryolarının çoğu (rules test dosyası var ama kapsamı sınırlı), add-price akışı test edilmiyor. En azından K1-K6'daki senaryolar için rules testleri eklenmeli (`firestore_rules_tests/` altyapısı hazır, kullan).
14. **`weeklySummary` config'i `appConfig/weeklySummary`** dokümanından okuyor ama `firestore.rules`'ta `appConfig` match'i yok → default deny; Admin SDK etkilenmez (sorun değil) ama admin panelden bu config'i düzenleyecek bir UI yazılırsa kurala takılacak.
15. **`onPriceGroupUpdate` bölge filtresi yalnız `price_drop` modunda**: `any_new_price` alarmı kuran kullanıcı, Türkiye'nin öbür ucundaki her raporda bildirim alır. Bilinçli tasarım olarak yorumlanmış; kullanıcı şikayetlerine hazırlıklı ol.

---

## 4. DOĞRU YAPILMIŞLAR (aynen korunmalı)

- **IAP güvenlik modeli örnek nitelikte:** Premium alanları client'a tamamen kapalı; `purchaseQueue` → `verifyPurchase` Cloud Function → Play Developer API doğrulaması → Admin SDK yazımı. Deneme fiyatı yerine yinelenen fiyatı gösteren `_recurringPrice` detayı da düşünülmüş.
- **Oturum geri yükleme mimarisi sağlam:** Cold start'ta `currentUser` yarışına karşı poll + stream + timeout'lu çift emniyet; "restore beklenirken asla login gösterme" kuralı; explicit logout işaretiyle gereksiz beklemenin atlanması. Bu, force-close sonrası login'e düşme bug'larını doğru çözen olgun bir tasarım.
- **Firestore kurallarında saldırı yüzeyi bilinçli daraltılmış:** puan artışına +50 cap, trust sayaçlarına +1 cap ve `verified+wrong == total` invariant'ı, `priceHistory`'ye 800 eleman cap'i + impersonation engeli (`reportedByUid == auth.uid`), premium alanlarının immutable listesi, username create regex'i.
- **Username rezervasyonu** transaction'lı, çakışma varyantlı (`base_2`, `base_3`...), 90 gün cooldown hem client hem rules'ta.
- **Reklam katmanı doğru kurulmuş:** UMP consent → `MobileAds.initialize` sırası; debug'ta Google test unit'leri, release'te dart-define override; Pro kullanıcıya hiç reklam render edilmiyor; interstitial'a 60 sn cooldown.
- **Bildirim dedupe'i akıllıca:** çift tetikleyici (products + priceGroups) yarışını `create()` ile atomik claim ederek çözmüş; yazma başarısızsa kilidi geri alıyor.
- **Geçersiz FCM token temizliği** her push yolunda var.
- **TR fiyat parse'ı** ("1.234,56" binlik ayraç tuzağı) doğru ele alınmış + aykırı fiyat için onay diyaloğu.
- **Storage kuralları** boyut + content-type + uid klasörü + email_verified kombinasyonuyla sıkı; magic-byte ile görüntü tipi tespiti HEIC content-type sorununu çözüyor.
- **Türkiye il/ilçe whitelist normalizasyonu** ("İstanbul" vs "istanbul" ikilemesini kaynağında kesiyor).
- **Crashlytics/Analytics debug'ta kapalı**, boot hataları uygulamayı öldürmeden hata ekranına düşüyor.
- **CI**: analyze + test + engineering guardrails workflow'ları mevcut; release versionCode CI'da offset'le yönetiliyor.

---

## 5. İLERİDE PATLAYABİLECEKLER (ölçek/zaman riskleri)

1. **Firestore faturası** — Y1 (full-scan fallback) + Y2 (index'ler deploy edilmiyor) + Y5 (weeklySummary N+1) + Y6 (tüm katalog her istemciye) birleşince kullanıcı sayısı arttıkça maliyet doğrusal değil çarpımsal büyür. İlk yapılacaklar: scan fallback'i sil, index'leri deploy et.
2. **`products` doc 1MB limiti** — 800 entry cap'i ortalama entry ~1.2KB ise ~960KB eder; limit sınırında. Popüler bir ürün cap'e ulaşınca fiyat ekleme o ürün için kalıcı olarak reddedilir (kural `size() <= 800`). Mirror phase-out planı (Aşama 3) ertelenmemeli.
3. **Bildirim koleksiyonları sınırsız büyüyor** — `users/{uid}/notifications` ve `notificationDedupes` için TTL/temizlik cron'u yok (`expiresAfterDays` alanı yazılıyor ama işleyen yok). Firestore TTL policy tanımlanmalı.
4. **`priceGroups` client-side aggregation yarışları** — iki kullanıcı aynı anda rapor verdiğinde transaction'lar `avgPrice`/`reportCount`'u korur, ama kural cap'i (+1) nedeniyle transaction retry'ları contention altında sıkışabilir; Cloud Function aggregation'a geçiş bunu da çözer.
5. **`price_entries` 14 günlük `expiresAt`** yazılıyor ama TTL policy veya silme cron'u repo'da tanımlı değil — koleksiyon sınırsız büyür.
6. **Anonim hesap birikmesi** — misafir oturumları hiç temizlenmiyor; Firebase Auth'ta anonim kullanıcı sayısı şişer (Auth tarafında otomatik silme politikası açılabilir).
7. **`isAdmin()` her kural değerlendirmesinde 2 `get()` çağırabiliyor** (`||` kısa devre olsa da tek doc'a 2 erişim) — rules'ta `let` ile tek get'e indirilebilir; yüksek trafikte okuma maliyeti düşer.

---

## 6. EKSİKLER (olması beklenip olmayanlar)

- **Hesap silme Cloud Function'ı** (K1'in kalıcı çözümü).
- **Premium expiry düşürücü scheduled function** (Y4).
- **Bildirim/dedupe/price_entries için TTL temizliği** (Bölüm 5.3, 5.5).
- **`regionalDropPushEnabled` TODO'su kapanmış ama `app_state.dart:354`'teki yorum güncellenmemiş** — functions artık bu alanı okuyor; yanıltıcı yorum silinmeli.
- **Rate limiting**: fiyat ekleme/yorum için App Check veya sunucu taraflı hız sınırı yok. `dedupeKey` aynı gün aynı fiyatı engelliyor ama farklı fiyatlarla spam mümkün. Firebase App Check etkinleştirilmesi önerilir.
- **iOS tarafı**: repo'da `ios/` klasörü yok (Android-only build). Pubspec yorumları iOS'tan bahsediyor; bilinçli bir karar değilse not edilmeli.
- **Öneri**: `flutter analyze`'ı yerelde de zorunlu kılan bir pre-commit hook / `scripts/check_engineering_rules.sh` entegrasyonu zaten var — CI yeşil kalsın diye PR'larda çalıştığından emin ol.

---

## 7. ÖNCELİKLİ AKSİYON LİSTESİ

| # | İş | Etki | Eforu |
|---|---|---|---|
| 1 | Hesap silmeyi Cloud Function'a taşı / rules düzelt (K1) | KVKK & Play uyumu | Orta |
| 2 | Doğrulama sonrası `getIdToken(true)` (K2) | Yeni kullanıcı deneyimi | Çok düşük |
| 3 | Yorum like: kural düzelt veya butonu kaldır (K3) | Görünür bug | Düşük |
| 4 | Fonksiyonlardaki full-scan fallback'i sil + index deploy'u pipeline'a ekle (Y1+Y2) | Maliyet | Düşük |
| 5 | `users` read'i owner/admin'e daralt (K7) | Gizlilik | Düşük |
| 6 | User create'te gamification alanlarını sıfıra zorla (K6) | Veri bütünlüğü | Düşük |
| 7 | priceGroups aggregation'ı Cloud Function'a taşı (K4+K5) | Veri bütünlüğü | Yüksek |
| 8 | Premium expiry cron'u ekle (Y4) | Gelir/entitlement doğruluğu | Düşük |
| 9 | Admin pending store index'i ekle (Y3) | Admin paneli | Çok düşük |
| 10 | Yorum boyut kurallarını eşitle (Y9) | Tutarlılık | Çok düşük |

---

## 8. SAYFA BAZLI İNCELEME (UI katmanı)

Genel durum: sayfalar özenli yazılmış — `mounted` kontrolleri, hata snackbar'ları, boş/yükleniyor durumları, misafir kotası overlay'leri tutarlı. Sayfa sayfa tespitler:

| Sayfa | Durum | Not |
|---|---|---|
| Onboarding | ✅ | Slayt içerikleri gerçek davranışı anlatıyor, "+10 puan" koddaki sabitle tutarlı. Bitişte kayıtlı kullanıcı doğrudan MainScreen'e, diğerleri Login'e. |
| Login / Kayıt | ✅ | Versiyonlu KVKK + 18+ onayı (`_kConsentVersion 2026.05`) `users/{uid}.consents` + `ageConfirmedAt` olarak yazılıyor — Play Data Safety için sağlam temel. Google girişinde auth-sonrası Firestore hatası girişi düşürmüyor (doğru). |
| Ana sayfa (HomeTab) | ✅ | Bölge fallback'leri (`Türkiye geneli`) ve Pro'da reklam gizleme doğru. Banner carousel, scope kartı sorunsuz. |
| Keşfet (ExploreTab) | ✅ | Filtre/kategori preset tüketimi one-shot, sorun yok. |
| Sepet (BasketTab) | ✅ | Misafir 3-hesap kotası + Pro değilse cooldown'lu interstitial doğru sıralanmış. |
| Ürün detay | ⚠ | "Ben de gördüm" akışı **K2 (stale token)** yüzünden yeni doğrulanan kullanıcıda permission-denied verir; yorum beğenisi **K3** ile tamamen kırık. Legacy fiyat geçmişi oy butonları rules ile uyumlu, çalışır. |
| Yorumlar bölümü | ⚠ | K3 (beğeni) + Y9 (501-1000 karakter yorum düzenlenemez). |
| Bildirim Merkezi | ✅ | Dismissible + silme yarışı bilinçli çözülmüş, izin-kapalı banner'ı var. |
| Doğrulama e-postası ekranı | ⚠ | Cooldown/tekrar-gönder akışı iyi; ama K2 nedeniyle "Doğruladım" sonrası katkı aksiyonları ~1 saat reddedilebilir — **ilk gün deneyimini bozan en kritik sayfa bug'ı**. |
| Paywall | ✅ | Restore + sunucu doğrulaması bekleme akışı doğru; mağaza kapalıyken net hata; 434 satır widget testi var. |
| Profil > Hesap | 🔴 | **K1**: hesap silme veriyi silmiyor. |
| Profil > Dil | ⚠ | İngilizce seçeneği sunuluyor ama yalnız ~211 string çevrili (Ayarlar/Bildirim ekranları); ana sayfa, keşfet, sepet, ürün detay, login tamamen hardcoded Türkçe. EN seçen kullanıcı **yarı Türkçe yarı İngilizce** arayüz görür. Ya seçeneği gizle ya çeviriyi tamamla. |
| Bölgesel liderlik | ✅ | Pro/free limit ayrımı (500/200) çalışıyor. |
| Watchlist / alarmlar | ✅ | Alarm listesi + silme akışı sorunsuz. |
| Admin ekranları | ⚠ | Bekleyen şubeler ekranı **Y3** (eksik index) ile boş düşebilir; priceGroup reset **K5** ile her zaman hata verir. |
| Splash | ⚠ | Dark mode'da açık tema flaşı (kozmetik). |

---

## 9. PLAY STORE DEĞERLENDİRMESİ

### 9a. Teknik hazırlık — 7/10
`targetSdk 35`, `minSdk 23`, R8 + shrinkResources, release imzalama key.properties'ten, `usesCleartextTraffic=false`, CI'da monoton versionCode, Crashlytics/Analytics release'te açık, UMP consent akışı doğru. Android tarafı yayına teknik olarak hazır sayılır.

### 9b. Policy hazırlık — 5/10 (blocker'lar var)
1. 🔴 **Hesap silme (K1)** — Play'in "hesap oluşturuluyorsa uygulama içi hesap silme + veri silme" politikası zorunlu. Buton var ama **Firestore verisi gerçekte silinmiyor** → beyan ile gerçek çelişiyor; reddedilme/kaldırılma riski. Ek olarak Play, uygulama dışından erişilebilir bir "hesap silme talebi" web URL'i de istiyor — netlify sayfalarına eklenebilir.
2. 🔴 **Data Safety çelişkisi (K7)** — formda "veri 3. taraflarla paylaşılmıyor" denecek ama telefon numarası her giriş yapan kullanıcı tarafından okunabiliyor; kural daraltılmadan form beyanı riskli.
3. ⚠ **İçerik derecelendirme** — kullanıcı üretimi içerik (yorum + fiyat) var: IARC anketinde "UGC var, moderasyon var" beyanı gerekir; şikayet/moderasyon mekanizması mevcut (✅ `reports`, admin panel), bu iyi.
4. ⚠ **AdMob** — gerçek app ID manifest'te (✅); `app-ads.txt` alan adına konmalı, reklam + UGC kombinasyonunda içerik derecelendirmesi tutarlı olmalı. 18+ beyanı alındığı için "aile programı" hedeflenmemeli.
5. ⚠ **Abonelikler** — `fr_pro_monthly` / `fr_pro_yearly` SKU'ları Play Console'da tanımlı ve aktif olmalı; `verifyPurchase` service account'una Play Console'da Finance rolü verilmeli — **yoksa premium hiç açılmaz** ve para alınıp entitlement verilmeyen kullanıcı şikayeti doğar. Y4 (expiry cron eksik) de gelir doğruluğunu etkiliyor.
6. ✅ Gizlilik politikası + sözleşme URL'leri canlı (netlify), kayıtta versiyonlu onay alınıyor.

### 9c. Pazar hazırlığı / ürün gerçekçiliği
Fikir doğru kategoride: Türkiye'de fiyat takibi talebi gerçek ve kanıtlanmış (Cimri, Marketfiyatı, broşür uygulamaları). Teknik altyapı bu ölçekteki bir indie ürün için ortalamanın üstünde. **Ana risk teknik değil, soğuk başlangıç (cold start):** topluluk verisiyle çalışan uygulama boş açılırsa kullanıcı ikinci kez açmaz; rakipler hazır veriyle geliyor.

Öneriler:
1. **Seed veri stratejisi** — lansmanda en az 1-2 pilot şehir/ilçede gerçek raf fiyatı hazır olsun (`scripts/import_products_firestore.py` altyapısı zaten var). Boş "Türkiye geneli" feed'iyle çıkma.
2. **Pilot bölge lansmanı** — tüm Türkiye yerine tek şehirde yoğun başla; yoğunluk topluluk uygulamalarında her şeydir.
3. **Retention kancaları hazır** — alarm + haftalık özet + rozet/streak sistemi doğru kurgulanmış; K2 düzeltilmeden bunların hiçbiri yeni kullanıcıda çalışmaz, önce onu düzelt.
4. **Internal → closed test** — Play'in yeni geliştirici hesaplarında 12 test kullanıcısı / 14 gün kapalı test şartı olabilir; planla. Pre-launch report'ta Crashlytics'i izle.
5. **ASO** — ekran görüntüleri, kısa tanıtım videosu, "market fiyat karşılaştırma" anahtar kelimeleri.

### 9d. Lansman öncesi sıralı yapılacaklar
1. K1 (hesap silme) + K7 (users read) → policy blocker'ları
2. K2 (`getIdToken(true)`) + K3 (beğeni) → ilk gün deneyimi
3. Y1+Y2 (full-scan + index deploy) → kullanıcı gelince fatura sürprizi olmasın
4. Play Console: SKU'lar + service account Finance rolü + Data Safety formu + hesap silme URL'i
5. EN dilini gizle veya tamamla
6. Seed veri + pilot bölge planı
7. Y4 (premium expiry cron) — ilk abonelik yenileme dönemi öncesi

---

## 10. UYGULANAN DÜZELTMELER (2026-07-02, bu branch'te)

Rapordaki bulguların önemli kısmı aynı branch'te koda işlendi:

### Güvenlik / kural düzeltmeleri
- **K1 — Hesap silme:** Yeni `deletionRequests/{uid}` koleksiyonu (rules) + `processAccountDeletion` Cloud Function'ı eklendi. Function, Admin SDK ile user doc + TÜM alt koleksiyonları (`recursiveDelete`), username rezervasyonunu, Storage klasörlerini (`user_profiles/`, `price_proofs/`, `product_image_submissions/`) ve Auth hesabını siler. Client akışı (`profile_screens._deleteAccount`) artık talep doc'u yazar; recent-login yoksa bile silme sunucuda tamamlanır.
- **K2 — Stale token:** `reloadAndCheckVerification` artık doğrulama sonrası `getIdToken(true)` ile ID token'ı zorla yeniler — yeni doğrulanan kullanıcının katkı yazımları anında çalışır.
- **K3 — Yorum beğenisi:** Rules'a `hasSafeCommentLikeToggle` eklendi: doğrulanmış kullanıcı yalnız kendi uid'ini `likedBy`'a ekleyip çıkarabilir, `likes == likedBy.size()` zorunlu. Client `toggleCommentLike`'a `_ensureEmailVerified` kapısı eklendi.
- **K5 — Admin reset:** `priceGroups` update kuralına `isAdmin() ||` bypass eklendi; admin moderasyon reset'i artık çalışır.
- **K6 — Sahte gamification:** `hasSafeUserCreateDefaults` artık `contributions`, `verifyContributions`, `photoContributions`, `currentStreak`, `longestStreak`, `badges` alanlarını da doğumda sıfıra zorluyor.
- **K7 — Gizlilik:** `users/{uid}` read kuralı `isAdmin() || isOwner(uid)`'a daraltıldı (telefon/fcmToken sızıntısı kapandı; ekranlar denormalize yazar bilgisi kullandığı için client etkilenmiyor).
- **Y9 — Yorum boyutları:** create'e 2-1000 karakter sınırı eklendi; update limiti 500→1000'e çekildi (uyumsuzluk giderildi). Ölü `hasOnlyCommentOwnerWritableKeys` fonksiyonu kaldırıldı.
- Rules fixture'ı senkronlandı (`firestore_rules_tests/firestore.rules`).

### Cloud Functions / altyapı
- **Y1 — Maliyet bombası:** `onPriceGroupUpdate` ve `onProductPriceDrop`'taki `productAlerts` full-scan fallback'leri kaldırıldı (0 sonuçta bile tüm koleksiyonu tarıyordu).
- **Y2 — Index deploy:** `firebase-deploy.yml` komutuna `firestore:indexes` eklendi.
- **Y3 — Eksik index:** `store_places (isActive, status, createdAt DESC)` kompozit index'i eklendi — admin bekleyen şubeler ekranı çalışır.
- **Y4 — Premium expiry:** Günlük `premiumExpirySweep` scheduled function eklendi (06:00 TSİ): `isPremium=true && premiumUntil < now` olan hesapları düşürür. Gerekli `(isPremium, premiumUntil)` index'i eklendi.

### Client / UX
- Splash artık dark mode'da koyu palete geçiyor (beyaz flaş bitti).
- Ölü `checkout()` iskeleti (`deliveryFee`, `cartTotal`, `setRedeemPoints` vd.) kaldırıldı — rules'un puan-azaltma yasağına takılacak tehlikeli koddu.
- İngilizce dil seçeneği "English (Beta)" + "kısmi çeviri" açıklamasıyla etiketlendi (yarı Türkçe arayüz bug sanılmasın).
- Kullanılmayan 760KB JSON asset (`fiyatradar_marketler/urunler.json`) APK bundle'ından çıkarıldı (dosyalar repo'da duruyor).
- `regionalDropPushEnabled` ile ilgili bayat TODO yorumu güncellendi (functions alanı zaten okuyor).

### Engagement (kullanıcı bağlılığı)
- **Ana sayfaya "Günlük Seri" kartı eklendi** (`_DailyStreakCard`): mevcut streak, bugünkü katkı durumu ("serin risk altında" uyarısı dahil), 3/7/30 gün rozet hedefine altın progress bar ve "Fiyat ekle" CTA'sı. Misafirde "Hesap aç" varyantı gösterilir. Tamamı mevcut gamification verisinden beslenir — ek Firestore okuması yok.

### Premium değerlendirmesi
Mevcut Pro seti **yeterli ve gerçek** (hepsi kodda doğrulandı): reklamsız deneyim, sınırsız alarm (free 3), 12 ay fiyat grafiği (free 7 gün), akıllı sepet önerisi, liderlikte Top-500 (free 200), haftalık bölge özeti (config default Pro-only), Pro rozeti. Eksik olan tek şey pazarlamasıydı: paywall'da anlatılmayan **"Haftalık bölge özeti"** ve **"Liderlikte Top 500"** ayrıcalıkları hem satış listesine hem "elindekiler" checklist'ine eklendi. `premiumExpirySweep` ile entitlement doğruluğu da güvenceye alındı.

### Hâlâ açık kalanlar (bilinçli ertelendi)
- **K4 — priceGroups fiyat manipülasyonu:** kalıcı çözüm aggregation'ın Cloud Function'a taşınması (büyük refactor; `submitRegionalPrice` transaction'ının yeniden tasarımı gerekir). Kural yüzeyi mevcut cap'lerle sınırlı kalmaya devam ediyor.
- Y5 (weeklySummary N+1), Y6 (katalog tam indirme / priceHistory mirror phase-out), Y7 (priceReports çift şema), Y8 (çoklu FCM token) — mimari işler, ayrı sprint önerilir.
- Deploy sonrası yapılacaklar: `firebase deploy` (functions + rules + indexes) çalıştırılmalı; rules emulator testleri (`firestore_rules_tests`) CI'da koşulmalı.

---

## 11. OTURUM KALICILIĞI + 2026 UI/UX TURU (2026-07-02, ikinci geçiş)

### 11a. "Uygulamaya girmeyince otomatik çıkış" bug'ı — kök neden analizi ve düzeltmeler
Semptom: uygulama bir süre açılmayınca sonraki soğuk açılışta login ekranı geliyor.
Tespit edilen üç ayrı mekanizma, üçü de kapatıldı:

1. **Yavaş restore + 8 sn timeout** — Play Store uygulamayı arka planda güncellediğinde bir sonraki açılış "ilk soğuk açılış"tır ve Firebase Auth'un disk restore'u 8 sn sınırını aşabiliyordu → AuthGate `timeout` ile login'e düşüyordu. Düzeltme: `SessionDiagnostics.expectsPersistedSession()` (daha önce kullanıcı görüldü + manuel çıkış yok) true iken deadline login'e düşmek yerine **2 kez 10'ar sn uzatılır**; `restoreAlreadyAttempted` hızlı-login kısayolu da aynı korumaya bağlandı.
2. **Bayat explicit-logout bayrağı** — logout'un yarıda kalması (işaret yazıldı, signOut tamamlanmadı) durumunda bayrak sonsuza dek true kalıp her açılışta login'i öne alıyordu. Düzeltme: `recordAuthSeen` canlı bir oturum gördüğü anda bayrağı temizler.
3. **Android Auto Backup bayat auth-state geri yüklüyordu** — `allowBackup` hiç set edilmemişti (default **true**): cihaz değişimi/yeniden kurulumda Firebase Auth'un disk durumu + uygulamanın kendi bayrakları (explicit-logout dahil!) eski haliyle geri gelebiliyordu. Düzeltme: `android:allowBackup="false"` + `fullBackupContent="false"` + Android 12+ için `dataExtractionRules` (cloud-backup ve device-transfer tamamen kapalı).

### 11b. 2026 UI/UX cilası
Mevcut tasarım sistemi zaten üst seviye (espresso+altın palet, global Dialog/SnackBar/BottomSheet/PageTransitions temaları, fade-through geçişler, giriş animasyonları). Eksik olan üç modern katman eklendi:
- **Edge-to-edge**: `SystemUiMode.edgeToEdge` + şeffaf status/navigation bar, ikon parlaklığı temaya bağlı (`fr_theme` `systemOverlayStyle` + MaterialApp seviyesinde senkron). Android 15'in zorunlu kıldığı görünüm artık tüm sürümlerde tutarlı.
- **Predictive back** (Android 14+): `android:enableOnBackInvokedCallback="true"`.
- **Dokunsal geri bildirim**: `frHaptic()` / `frHapticSuccess()` token helper'ları; favori, oy, "Ben de gördüm", yorum beğenisi, fiyat gönderimi başarısı, streak CTA ve satın alma akışına bağlandı.

Tutarlılık notu: sayfalardaki ham `AlertDialog`/`SnackBar` kullanımları global tema (DialogTheme/SnackBarTheme) sayesinde zaten tek stile iniyor — ekran ekran müdahale gerekmedi.

### 11c. Play Store final eksik listesi (kod dışı — Console işleri)
Kod tarafı blocker'ları bu branch'te kapandı. Kalanlar operasyonel:
1. `firebase deploy --only functions,firestore:rules,firestore:indexes` çalıştır (yeni CF'ler + kurallar + index'ler canlıya insin).
2. Play Console: `fr_pro_monthly` / `fr_pro_yearly` aboneliklerini tanımla + servis hesabına **Finance** rolü (yoksa premium doğrulama çalışmaz).
3. **Data Safety formu** — `docs/play_console_readiness.md`'deki veri listesi hazır; artık "users okuması owner-only" olduğu için beyanlar tutarlı.
4. **Hesap silme URL'i** — Play, uygulama dışından erişilebilir bir silme talep sayfası ister; netlify sitesine basit bir "hesap silme talebi" sayfası ekle (uygulama içi silme artık gerçek çalışıyor).
5. Gizlilik politikası URL'ini Console'a gir (sayfa zaten canlı).
6. **IARC içerik derecelendirme** anketi: UGC var + moderasyon/şikayet mekanizması var olarak beyan et.
7. AdMob: alan adına `app-ads.txt`, ödeme profili.
8. Yeni geliştirici hesabıysa: **kapalı test şartı** (12 test kullanıcısı / 14 gün) — planla.
9. Lansman verisi: pilot il/ilçe için seed fiyat verisi (boş feed'le çıkma).
10. İlk sürüm sonrası pre-launch report + Crashlytics'i izle.

---

*Bu rapor ve 10-11. bölümlerdeki düzeltmeler `claude/kanka-app-review-w25ca9` branch'indedir.*
