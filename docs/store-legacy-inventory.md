# Store Legacy Inventory (Branch/Location Sonrası)

Bu envanter, branch/location kaldırma kararı sonrası repoda kalan store/branch/location referanslarını **dosya bazlı** izlemek için hazırlanmıştır.

## Sınıflandırma anahtarı

- **active core**: Yeni çekirdek store kararını bugün fiilen taşıyan alanlar.
- **inactive legacy**: Çekirdek karar mekanizmasını etkilemeyen, geçmiş uyumluluk için kalan alan/referanslar.
- **removable later**: Sonraki cleanup dalgasında güvenle sökülebilecek adaylar.
- **keep-for-compat**: Hemen sökülemeyecek, backward compatibility riski taşıyan alanlar.

## A) Active core

### A.1 Chain/store canonical kimliği
- `lib/services/firestore_service.dart`
  - `canonicalStoreId` hesaplaması: `(price.chainId ?? price.selectedStoreId ?? price.branchStoreId)`
  - Yazımda `storeId`, `chainId`, `selectedStoreId` birlikte normalize ediliyor.
- `lib/providers/add_price_provider.dart`
  - Fiyat bildirimi payload’ında seçili market zinciri kimliği temel alınıyor (`selectedStoreId` + `chainId`).

### A.2 Online/fiziksel ayrımı
- `lib/models/store_model.dart`
  - `storeType` normalize ediliyor (`store` / `online_store`).
  - `type` ve `isOnline` legacy map edilse de karar noktası `storeType` + `isOnline` türetmesi.
- `lib/providers/add_price_provider.dart`
  - UI tarafında online/fiziksel filtreleme korunuyor.

### A.3 Opsiyonel kısa not
- `lib/providers/add_price_provider.dart`
  - `userNote` yalnız opsiyonel metin olarak set ediliyor.
- `lib/models/price_model.dart`
  - `userNote` modelde nullable olarak taşınıyor; branch identity yerine kullanılmıyor.

## B) Inactive legacy

### B.1 Branch alanları (alias/compat)
- `lib/models/price_model.dart`
  - `branchStoreId` alanı zorunlu tutuluyor ancak `storeId/branchId` alias fallback’i ile okunuyor.
  - `toFirestore` içinde aynı kimlik hem `branchStoreId` hem `branchId` hem `storeId` olarak yazılıyor.
- `firestore.rules`
  - Price payload allow-list hâlâ `branchStoreId` ve `branchId` içeriyor.

### B.2 Location alanları
- `lib/models/store_model.dart`
  - `lat/lng` + `geoPoint/location/coordinates` fallback parse yapısı sürüyor.
- `lib/models/store_suggestion_model.dart`
  - Store suggestion akışında `lat/lng` tutuluyor.
- `lib/models/product_detail_api_model.dart`
  - API response modellerinde `storeLocation` alanı taşınıyor.

### B.3 Nearest/maps davranış kalıntıları
- `lib/services/cart_comparison_service.dart`
  - `distanceKm` ve `nearestMarket` hesapları var.
- `lib/screens/cart/cart_result_tab.dart`
  - Maps açma (`https://maps.google.com/?q=lat,lng`) ve “En Yakın Markete Git” UI metni bulunuyor.

### B.4 Branch sabit kullanımı (çekirdek dışı akış)
- `lib/screens/deals/deals_screen.dart`
  - Stock report için `const branchId = 'default'` kullanımı.
- `lib/services/firestore_service.dart`
  - `submitStockReport/getStockSummary` akışlarında `branchId` parametresi kullanılıyor.

## C) Removable later (cleanup adayı)

> Bu grup, ürün çekirdeğini bozmayacak şekilde sonraki dalgada ele alınması önerilen alanlardır.

1. Cart sonucu içindeki nearest/maps UI metinleri ve `_openMaps` davranışı.
2. Cart karşılaştırma `distanceKm` / `nearestMarket` alanları (location-first karar olmadığı için).
3. `StoreService.fetchStores({lat,lng})` imzasındaki kullanılmayan `lat/lng` parametreleri.
4. AddPrice dışı legacy “branch” log/metinleri (örn. debug loglarda “nearby branch”).

## D) Keep-for-compat (hemen sökülmemeli)

1. `PriceModel.fromFirestore` fallback zinciri (`branchStoreId ?? branchId ?? storeId`).
2. `PriceModel.toFirestore` içinde legacy alanların birlikte yazılması (`branchStoreId`, `branchId`, `storeId`).
3. `firestore.rules` allow-list içindeki `branchStoreId/branchId` kabulü.
4. `StoreModel` tarafındaki `type/isOnline` legacy normalization (eski doküman ve kayıtları okumak için).

## E) Karar mekanizmasına etkisi olmayanlar (özet)

Aşağıdaki kalemler mevcut çekirdek ürün kararını belirlemiyor; çoğu read-compat veya legacy UI davranışıdır:

- Branch alias alanları (`branchId`, `branchStoreId`) asıl kimlik olarak değil compatibility alias’ı olarak kalıyor.
- Konum tabanlı alanlar (`lat`, `lng`, `storeLocation`, maps/nearest) çekirdek add-price kararında zorunlu değil.
- Opsiyonel `userNote` yalnızca serbest kullanıcı notu; branch identity değildir.

## F) Sonraki cleanup dalgası için önerilen sıra

1. Cart nearest/maps akışını policy ile hizalama (UI + service + model).
2. Branch alias kullanımını write-path’te kademeli daraltma (read fallback korunarak).
3. Rules güncellemesini uygulama payload daraltmasıyla birlikte yapmak.
4. En sonda model-level legacy alanlarını (geri uyumluluk migration tamamlandığında) kaldırmak.
