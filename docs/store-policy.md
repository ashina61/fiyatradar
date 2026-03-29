# Store Policy (Canonical)

Bu doküman, FiyatRadar store modeli için **resmi ve bağlayıcı** ürün politikasıdır.

## 1) Temel model birimi

1. FiyatRadar store modelinin ana birimi **market zinciri (chain)**’dir.
2. Price report ve karşılaştırma akışları chain/store kimliği üzerinden çalışır.

## 2) Branch/şube politikası

1. Ürün çekirdeğinde branch/şube bazlı ayrı bir store identity modeli **yoktur**.
2. `branchId` / `branchStoreId` gibi alanlar yalnızca legacy veri uyumluluğu amacıyla taşınır; yeni karar mekanizmasının semantik kaynağı değildir.

## 3) Location tabanlı store politikası

1. Ürün çekirdeğinde konum tabanlı store sistemi **yoktur**.
2. Çekirdek akışta aşağıdakiler zorunlu değildir ve ürün kararını belirlemez:
   - `lat` / `lng`
   - `storeLocation`
   - `mapsUrl` / yol tarifi davranışları
   - “nearest store” seçimi

## 4) Online/fiziksel ayrımı

1. `storeType`/`type` üzerinden online vs fiziksel ayrımı korunur.
2. Bu ayrım, branch/location kimliği oluşturmaz; yalnızca mağaza türünü ifade eder.

## 5) Opsiyonel kullanıcı notu

1. Kullanıcı fiyat bildirimi sırasında **opsiyonel kısa not** bırakabilir (`userNote`).
2. `userNote`, kullanıcı bağlamı sağlar; **branch identity yerine geçmez**.

## 6) Genişletme kısıtı

1. Yeni feature’lar store modelini branch/location-first olacak şekilde genişletemez.
2. Branch/location alanı ekleme veya yeniden aktive etme ihtiyacı oluşursa, önce bu policy dosyası güncellenir ve açık ürün kararı dokümante edilir.

## 7) Uygulama kuralı

1. Bu policy, `docs/engineering-ruleset.md` içindeki hard rule set ile birlikte değerlendirilir.
2. Policy’ye aykırı davranan değişiklikler merge edilmez.
