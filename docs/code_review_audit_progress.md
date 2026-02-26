# Code Review Audit Progress

Bu doküman `CODE_REVIEW_AUDIT.md` içindeki faz görevlerinin uygulama ilerlemesini takip etmek için eklendi.

Detay operasyonel takip listesi: `docs/code_review_audit_todos.md`.

## Hızlı Kazanımlar Durumu

- [x] Türkçe karakter ve metin normalizasyonu (yüksek görünürlüklü ekranlar + admin modülleri)
- [x] `firebaseInitializedNotifier.value` kullanımının ekran/provider katmanında temizlenmesi
- [x] Auth ekranlarında provider kullanımının korunması (`authServiceProvider`)
- [x] Yorum raporlama TODO'sunun backend çağrısına bağlanması
- [~] Debug log temizliği (kritik `print` çağrıları `debugPrint` + `kDebugMode` ile hizalandı, repo geneli tarama sürüyor)
- [~] Firebase Security Rules yazımı ve testleri (rules mevcut; regresyon testi kapsamı genişletiliyor)
- [~] FirestoreService parçalama (domain bazlı servis ayrımı; comments + notifications + banners + users-admin + product-engagement + product-catalog + campaigns + search-history + saved-products + categories domainleri ayrıştırıldı, kalan domainler devam ediyor)
- [ ] Admin panelin modüler ayrıştırması
- [ ] Test kapsamını hedef seviyelere çıkarma

## Faz Bazlı Özet

### Faz 1 (Acil)
- Durum: **Devam ediyor**
- Tamamlananlar: UI metin standardizasyonu, bazı hızlı kazanımlar, yorum raporlama entegrasyonu
- Kalan kritikler: security rules testlerinin CI/emulator bağımlılıklarıyla tam doğrulanması + test kapsamı

### Son Güncelleme (26 Şubat 2026)
- `firestore.rules` içinde `priceReports` owner update yetkileri daraltıldı; moderasyon alanları (`status`, `verificationStatus`) owner tarafından değiştirilemez hale getirildi.
- Rules testlerine owner güncelleme sınırları için pozitif/negatif senaryolar eklendi.
- Rules testlerinde `priceReports` için ek kapsam: owner'ın `productId` gibi disallowed alanları güncelleyememesi ve admin'in moderasyon alanlarını güncelleyebilmesi doğrulandı.
- `priceReports` create aşamasında moderasyon alanları için güvenli varsayılan kuralı eklendi (kullanıcı `verified` veya `removed` statüsüyle kayıt açamaz).
- `comments` create kuralında güvenli varsayılanlar eklendi (`likes`/`likedBy` pre-populate engeli) ve buna karşı negatif test senaryoları yazıldı.
- `comments` update yetkileri owner için daraltıldı (yalnızca güvenli alanlar), `likes`/`likedBy` manipülasyonuna karşı update negatif testleri eklendi.
- `users` create kuralı güvenli varsayılanlarla sıkılaştırıldı (`points`/trust/admin alanlarında forge engeli) ve buna karşı negatif testler eklendi.
- `users` rules test kapsamı genişletildi: admin role/isAdmin/uid mismatch create saldırı senaryoları negatif testlerle doğrulandı.
- FirestoreService parçalama için ilk kod adımı atıldı: comments işlemleri `CommentService` içine ayrıştırılıp FirestoreService üzerinden delege edildi.
- FirestoreService parçalama ikinci adım: notifications işlemleri `NotificationService` içine ayrıştırılıp FirestoreService üzerinden delege edildi.
- FirestoreService parçalama üçüncü adım: banner işlemleri `BannerService` içine ayrıştırılıp FirestoreService üzerinden delege edildi.
- FirestoreService parçalama dördüncü adım: users-admin işlemleri `UserAdminService` içine ayrıştırılıp FirestoreService üzerinden delege edildi.
- FirestoreService parçalama beşinci adım: ürün etkileşim işlemleri (`incrementViewCount`, `registerProductShare`) `ProductEngagementService` içine ayrıştırılıp delege edildi.
- FirestoreService parçalama altıncı adım: ürün katalog işlemleri (`getTrendingProducts`, `getRecommendedProducts`, `getProductsByIds`, product CRUD) `ProductCatalogService` içine ayrıştırılıp delege edildi.
- FirestoreService parçalama yedinci adım: kampanya işlemleri (`getCampaignById`, `getAllCampaigns`, `getActiveCampaigns`, campaign CRUD, banner-campaign ürün eşleme) `CampaignService` içine ayrıştırılıp delege edildi.
- FirestoreService parçalama sekizinci adım: arama geçmişi işlemleri (`saveSearchHistory`, `getSearchHistory`, `clearSearchHistory`) `SearchHistoryService` içine ayrıştırılıp delege edildi.
- FirestoreService parçalama dokuzuncu adım: kayıtlı ürün akışı `SavedProductService` içine ayrıştırılıp delege edildi.
- FirestoreService parçalama onuncu adım: kategori işlemleri (`getCategories`, `addCategory`, `updateCategory`, `deleteCategory`) `CategoryService` içine ayrıştırılıp delege edildi.
- `points_events` yazma yüzeyi daraltıldı: create/update/delete yalnızca admin yetkisine çekildi ve suistimal senaryoları testlere eklendi.
- `adminActions` create payload doğrulaması sıkılaştırıldı (zorunlu alan + allowlist), boş/ekstra alan suistimalleri için negatif testler eklendi.
- `adminActions` create kuralında `createdAt` alanı zorunlu/timestamp olacak şekilde sıkılaştırma yapıldı; eksik alan için negatif test eklendi.
- `points_events` create payload doğrulaması allowlist + zorunlu alan kontrolleriyle sertleştirildi; ekstra/eksik alan suistimalleri için negatif testler eklendi.
- `points_events` payloadında `pointsDelta` için integer zorunluluğu ve `points` alanı varsa `pointsDelta` ile eşitlik kontrolü eklendi; buna karşı negatif test senaryoları yazıldı.
- Firestore rules testlerine yeni senaryolar eklendi:
  - `priceReports` oluşturma yetkisi (kendi `createdByUid` alanı zorunluluğu)
  - `adminActions` okuma/yazma yetkisi (admin + `actorUid == auth.uid` doğrulaması)
- `FirestoreService` içinde kalan bir adet `print` çağrısı `kDebugMode` koşullu `debugPrint` ile değiştirildi.

### Faz 2 (Kısa Vade)
- Durum: **Başlamadı (planlama gerekli)**
- Kalanlar: servis ayrıştırma, admin modülerleşme, tip güvenliği, memory leak iyileştirmeleri

### Faz 3 (Orta Vade)
- Durum: **Başlamadı**

### Faz 4 (Uzun Vade)
- Durum: **Başlamadı**

## Not

Bu dosya ilerleme görünürlüğü içindir; `CODE_REVIEW_AUDIT.md` ana denetim raporu olarak korunur.
