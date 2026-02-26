# Faz 2-3-4 Uygulama Durumu (Bu PR)

Bu doküman, `CODE_REVIEW_AUDIT.md` içindeki Faz 2/3/4 maddelerine yönelik bu PR'da atılan somut adımları özetler.

## Faz 2 (Kısa vade) - Mimari parçalama başlangıcı
- [x] `FirestoreService` bağımlılığını parçalama için domain servis katmanı eklendi:
  - `BrandDomainService`
  - `StoreDomainService`
- [x] `product_provider.dart` içinde brand/store stream provider'ları doğrudan `FirestoreService` yerine yeni domain servis sağlayıcıları üzerinden çalıştırıldı.
- [x] Admin moderasyon akışı için `AdminModerationDomainService` eklendi ve rapor/maintenance provider'ları doğrudan `FirestoreService` yerine bu facade üzerinden çalıştırıldı.
- [x] Ürün öneri moderasyonu için `ProductSuggestionDomainService` eklendi ve `pendingProductSuggestionsProvider` ile ilgili admin aksiyonları facade üzerinden çalıştırıldı.
- [x] Admin kullanıcı yönetimi için `AdminUserManagementDomainService` eklendi; kullanıcı güncelleme/ban/silme aksiyonları bu facade üzerinden çalıştırıldı.
- [x] Admin marka yönetimi için `AdminBrandManagementDomainService` eklendi; marka ekleme/güncelleme aksiyonları facade üzerinden çalıştırıldı.
- [x] Aktüel yönetimi için `ActualAdminDomainService` eklendi; admin actual/actual item listeleme ve yönetim aksiyonları facade üzerinden çalıştırıldı.
- [x] Admin kategori yönetimi için `AdminCategoryManagementDomainService` eklendi; kategori ekleme/güncelleme/silme aksiyonları facade üzerinden çalıştırıldı.
- [x] Admin banner yönetimi için `AdminBannerManagementDomainService` eklendi; banner ekleme/güncelleme aksiyonları facade üzerinden çalıştırıldı.
- [x] Admin kampanya yönetimi için `AdminCampaignManagementDomainService` eklendi; kampanya ekleme/güncelleme/silme aksiyonları facade üzerinden çalıştırıldı.
- [x] Admin panel modüler kırılımı ilerletildi: `admin_brand_management_tab.dart`, `admin_statistics_tab.dart`, `admin_reports_management_tab.dart`, `admin_user_management_tab.dart`, `admin_product_suggestions_tab.dart` ve `admin_badge_achievements_tab.dart` ayrı dosyalara taşındı.

## Faz 3 (Orta vade) - Routing + test kapsamı artışı
- [x] Merkezi router (`go_router`) eklendi: `lib/app_router.dart`.
- [x] `MaterialApp` -> `MaterialApp.router` dönüşümü yapıldı.
- [x] Başlangıç geçidi (`AppStartGate`) route tabanlı akışa taşındı.
- [x] Yeni unit test dosyaları eklendi:
  - `test/user_model_unit_test.dart`
  - `test/product_model_unit_test.dart`

## Faz 4 (Uzun vade) - Operasyonel temel
- [x] CI pipeline temeli eklendi: `.github/workflows/flutter_ci.yml`.
- [x] Cloud Functions geçiş planı eklendi: `docs/phase4_cloud_functions_plan.md`.

## Not
Faz 2-3-4 başlıklarının tamamı çok geniş kapsamlı olduğu için bu PR'da **temel altyapı ve iskelet adımlar** tamamlanmıştır; kalan büyük refactor parçaları (örn. tüm feature'ların tam feature-based mimariye taşınması, FirestoreService'in tamamen ayrıştırılması, admin ekranının tümden modüler kırılımı) sonraki dilimlerde devam ettirilmelidir.
