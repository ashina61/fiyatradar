# Code Review Audit TODO Listesi

Bu dosya, `CODE_REVIEW_AUDIT.md` için operasyonel takip listesi olarak hazırlanmıştır.
Amaç: bir sonraki adımlarda "neyi yaptık / ne kaldı / neden bekliyor" net görünsün.

## 0) Anlık Sayım (26 Şubat 2026)

- Tamamlanan iş: **29**
  - 6 ana Done maddesi + Firestore rules/regresyon ve servis ayrıştırma başlığı altındaki 23 tamamlanmış alt madde.
- Kalan iş: **9**
  - 2 In Progress + 3 Not Started + 4 Bir Sonraki Sprint TODO maddesi.

## 1) Tamamlananlar (Done)

- [x] Türkçe metin/karakter normalizasyonu (yüksek görünürlüklü ekranlar + admin modülleri).
- [x] `firebaseInitializedNotifier.value` doğrudan erişimlerinin ekran/provider katmanında temizlenmesi.
- [x] Auth ekranlarında provider akışının korunması (`authServiceProvider`).
- [x] Yorum raporlama TODO'sunun backend çağrısına bağlanması.
- [x] `FirestoreService` içindeki kalan koşulsuz `print` çağrısının `kDebugMode` + `debugPrint` ile hizalanması.
- [x] Firestore rules regresyon testlerine ek senaryolar:
  - `priceReports`: owner-only create doğrulaması
  - `adminActions`: non-admin read engeli + `actorUid == auth.uid` kontrolü
  - `priceReports` owner update alanları daraltıldı (`status`/`verificationStatus` immutable)
  - `priceReports` create aşaması moderasyon alanları güvenli varsayılanlarla sınırlandı
  - `priceReports` update kuralları için admin override ve disallowed field negatif testi eklendi
  - `comments` create aşamasında `likes`/`likedBy` manipülasyonuna karşı güvenli varsayılan kuralı + testleri eklendi
  - `comments` update izinleri owner için güvenli alanlarla sınırlandı; likes/likedBy doğrudan update engeli testlerle doğrulandı
  - `users` create aşamasında points/trust/admin alanlarına güvenli varsayılan zorunluluğu ve negatif testler eklendi
  - `users` rules testleri admin role/isAdmin/uid mismatch create suistimallerini kapsayacak şekilde genişletildi
  - `points_events` koleksiyonunda yazma işlemleri admin-only hale getirildi ve regresyon testleri eklendi
  - `points_events` create payloadı allowlist + zorunlu alan kontrolüyle sertleştirildi ve negatif testler eklendi
  - `points_events` payloadında `pointsDelta` int zorunluluğu ve `points == pointsDelta` tutarlılık kontrolü eklendi
  - `adminActions` create payloadı allowlist + zorunlu alan kontrolüyle sertleştirildi ve negatif testler eklendi
  - `adminActions` create payloadında `createdAt` zorunlu + timestamp doğrulaması eklendi ve negatif testle doğrulandı
  - FirestoreService içinde comments domaini `CommentService` olarak ilk dilimde ayrıştırıldı (delege entegrasyonu yapıldı)
  - FirestoreService içinde notifications domaini `NotificationService` olarak ayrıştırıldı (delege entegrasyonu yapıldı)
  - FirestoreService içinde banners domaini `BannerService` olarak ayrıştırıldı (delege entegrasyonu yapıldı)
  - FirestoreService içinde users-admin domaini `UserAdminService` olarak ayrıştırıldı (delege entegrasyonu yapıldı)
  - FirestoreService içinde product-engagement domaini `ProductEngagementService` olarak ayrıştırıldı (view/share delege entegrasyonu yapıldı)
  - FirestoreService içinde product-catalog domaini `ProductCatalogService` olarak ayrıştırıldı (trending/recommended/crud/byIds delege edildi)
  - FirestoreService içinde campaigns domaini `CampaignService` olarak ayrıştırıldı (campaign CRUD/active/byId/byBanner delege edildi)
  - FirestoreService içinde search-history domaini `SearchHistoryService` olarak ayrıştırıldı (save/get/clear delege edildi)
  - FirestoreService içinde saved-products domaini `SavedProductService` olarak ayrıştırıldı (getSavedProducts delege edildi)
  - FirestoreService içinde categories domaini `CategoryService` olarak ayrıştırıldı (get/add/update/delete delege edildi)

## 2) Devam Edenler (In Progress)

- [ ] Debug log temizliği (repo genelinde kalan `debugPrint`/log standardizasyonu).
  - Durum: Kritik `print` temizlendi, kalan dosyalar için sistematik tarama devam edecek.
- [ ] Firebase Security Rules testlerinin tam koşulda çalıştırılması.
  - Durum: Testler yazılı; ortamda npm registry kısıtı nedeniyle bağımlılıklar kurulamadı.

## 3) Bekleyen Kritikler (Not Started)

- [~] FirestoreService parçalama (domain bazlı servis ayrımı; comments + notifications + banners + users-admin + product-engagement + product-catalog + campaigns + search-history + saved-products + categories domainleri ayrıştırıldı, kalan domainler devam ediyor).
- [ ] Admin panelin modüler ayrıştırması.
- [ ] Test kapsamını hedef seviyeye çıkarma (servis/provider/model/widget).

## 4) Bir Sonraki Sprint TODO (Önerilen Sıra)

- [ ] Firestore rules test altyapısını çalışır hale getir:
  - `firestore_rules_tests` bağımlılıklarının kurulabildiği ortamda `npm install && npm test` çalıştır.
  - Emulator ile CI uyumunu doğrula (`firebase emulators:exec`).
- [ ] FirestoreService için ilk güvenli parçalama dilimi:
  - `PriceService` ve `NotificationService` extraction planını çıkar.
  - Mevcut public API kırılmadan ara adapter katmanı ekle.
- [ ] Admin panelde ilk modüler kırılım:
  - Tab bazlı widget/screen dosyalarını bağımsızlaştır.
  - Veri erişimini ilgili servis/provider katmanına taşı.
- [ ] Test borcu için başlangıç paketi:
  - Kritik model serileştirme testleri
  - Auth + basket + price report provider unit testleri

## 5) Blokajlar / Riskler

- Ortamda `dart`/`flutter` CLI yok: yerel format ve Dart testleri burada koşturulamıyor.
- `firestore_rules_tests` için npm registry erişimi `403 Forbidden` ile bloklanıyor.
- Emulator tabanlı testler bağımlılık kurulumuna bağlı.

## 6) Çalışma Kuralı (Bu listeye göre ilerleme)

Her adımda aşağıdaki güncellenecek:
1. Done kutucukları
2. In Progress maddelerinin alt durumu
3. Blokaj / risk notları
4. Bir sonraki net TODO (1-3 madde)
