# FiyatRadar UI/UX Redesign Playbook (V1)

Bu döküman, "sil baştan" UI/UX dönüşümünü kontrollü ve ölçülebilir şekilde yürütmek için hazırlandı.
Amaç: estetik yenileme + dönüşüm iyileştirme + geliştirme hızını koruyan bir tasarım dili oluşturmak.

## 1) İki Tasarım Yönü

### A. Premium Güven ("Fintech Clean")
- **Ne hissettirir:** güvenilir, olgun, düzenli.
- **Kime uygun:** fiyat karşılaştırmada doğruluk ve şeffaflık vurgulamak isteyen ürünler.
- **Görsel dil:** düşük doygunluk, net boşluklar, güçlü tipografik hiyerarşi.
- **Örnek referans ruhu:** Stripe Dashboard + Linear sade düzeni.

**UI örnekleri**
- Hero: "Bugünün en iyi düşüşleri" kartı, yanında güven badge'i.
- Liste item: ürün adı + en iyi fiyat + "7 günde -%12" mini trend.
- CTA: tek bir primary aksiyon ("Fiyat alarmı kur"), ikincil butonlar ghost style.

### B. Hızlı Avcı ("Performance Commerce")
- **Ne hissettirir:** dinamik, hızlı karar verdiren, aksiyon odaklı.
- **Kime uygun:** mobilde seri karşılaştırma ve anlık kampanya takibi yapan kullanıcılar.
- **Görsel dil:** daha yüksek kontrast, güçlü durum renkleri, net mikro-etiketler.
- **Örnek referans ruhu:** modern e-commerce feed + trading app okunabilirliği.

**UI örnekleri**
- Hero: "Son 24 saatte en çok düşen ürünler" sıralı blok.
- Liste item: mağaza rozeti, kargo bilgisi, toplam maliyet satırı.
- CTA: sticky alt bar "3 mağazayı karşılaştır".

## 2) Tasarım Dili (Design Tokens)

Aşağıdaki token seti her iki yönü de destekler; yalnızca renk yoğunluğu/kontrast seviyesi değişir.

### 2.1 Renk Rolleri
- `primary`: ana aksiyonlar (CTA, aktif tab, önemli link)
- `surface`: ekran/kart ana zemin
- `surfaceVariant`: ikinci katman bloklar
- `success`: fiyat düştü
- `warning`: stok az / zaman sınırlı kampanya
- `error`: veri hatası / kritik işlem uyarısı
- `info`: tarafsız bilgilendirme banner'ı

**Durum örneği**
- Fiyat düşüş etiketi: success bg + success text
- Fiyat artışı etiketi: error değil, nötr `info` tonu (panik hissini azaltır)

### 2.2 Tipografi Ölçeği
- `Display`: 32/40 (yalnızca hero başlık)
- `Heading`: 24/32
- `Title`: 20/28
- `Body`: 16/24
- `Caption`: 14/20
- `Meta`: 12/16

**Kural:** Aynı ekranda 3'ten fazla metin boyutu kullanma.

### 2.3 Spacing ve Radius
- Spacing: `4, 8, 12, 16, 24, 32, 48`
- Radius: `12 (input)`, `16 (card)`, `24 (hero)`
- Grid: mobile 4-col, tablet/desktop 12-col

### 2.4 Motion
- Fast: `160-200ms`
- Base: `240-320ms`
- Emphasis: `360-480ms`
- Easing: `easeOutCubic`

**Kural:** Aynı view içinde 2'den fazla animasyon karakteri kullanma.

## 3) Ekran Önceliklendirme (Redesign Sırası)

1. **Arama + Sonuç Listeleme**
   - Ürünün kalbi; bilgi mimarisi ve kıyaslama deneyimi burada belirlenir.
2. **Ürün Detay + Fiyat Geçmişi**
   - Güven inşa eden kanıt ekranı; karar kalitesini artırır.
3. **Alarm Kurma Akışı (Guest + Member)**
   - Dönüşüm tıkanıklığını çözecek ana funnel.
4. **Karşılaştırma Sepeti / Basket**
   - Çoklu mağaza toplam maliyeti netleştirir.
5. **Profil + Bildirim Ayarları**
   - Retention ve tekrar kullanım katmanı.

## 4) Üç Kritik Akış için Wireframe İskeleti

### 4.1 Ana Sayfa (Home)
- Üst: arama alanı + kısa filtre chips
- Orta-1: "Günün Fırsatları" yatay kartlar
- Orta-2: "En çok takip edilen kategoriler"
- Alt: kişiye özel öneri feed

**Boş durum örneği:** "Takip ettiğin kategori yok, 3 kategori seçerek kişiselleştir." 

### 4.2 Sonuç Listeleme (PLP)
- Üst: query + sıralama + filtre butonu
- Gövde: ürün kartları (fiyat, mağaza, kargo, trend)
- Sticky alt: "Seçilen 2 ürünü karşılaştır"

**Filtre UX örneği:** modal yerine bottom sheet + tek dokunuşta uygula.

### 4.3 Ürün Detay (PDP)
- Üst: ürün görseli + isim + güven skoru
- Orta: fiyat geçmişi grafiği + fiyat düşüş noktaları
- Alt: mağaza listesi + toplam maliyet satırı
- Sticky CTA: "Fiyat alarmı kur"

**Mikrocopy örneği:** "Son 30 günde en düşük seviyeye %4 kaldı."

## 5) 30 Günlük Uygulama Planı

### Hafta 1 — Keşif ve Ölçüm
- Mevcut akışların heuristik analizi
- KPI baseline çıkarımı (search→detail, detail→alarm)
- 5 kullanıcı ile hızlı görüşme

**Çıktı:** sorun haritası + ölçüm dashboard taslağı

### Hafta 2 — IA + Wireframe
- Ana akışların düşük sadakat wireframe'i
- İçerik hiyerarşisi ve karar anları netleştirme
- Boş/hata/yükleniyor durumlarını tanımlama

**Çıktı:** onaylı wireframe seti

### Hafta 3 — UI Kit + High Fidelity
- Token dosyaları (renk, type, spacing, radius)
- Core component seti (Button, Input, Chip, ProductCard, PriceBadge)
- Home/PLP/PDP high-fidelity ekranları

**Çıktı:** tasarım dili + geliştirici handoff

### Hafta 4 — Uygulama + Validasyon
- Öncelikli ekranların implementasyonu
- Event tracking ve funnel metriklerinin canlı takibi
- 1 haftalık A/B veya phased rollout

**Çıktı:** canlı metrik raporu + iterasyon backlog'u

## 6) Başarı Ölçütleri (Örnek KPI)
- Search → PDP geçiş oranı: `%+15`
- PDP → Alarm kurulum oranı: `%+20`
- İlk içerik boyama algısı (UX algısı): daha "hızlı" hissi
- 7 günlük geri dönüş (retention): `%+8`

## 7) Hemen Başlamak İçin Kısa Brief Şablonu
Aşağıyı ekip içinde doldur:

- Hedef persona:
- Birincil iş hedefi (KPI):
- En kritik 3 ekran:
- Marka tonu (3 kelime):
- Referans alınacak 2 ürün:
- Teknik kısıtlar:
- MVP canlı tarihi:

Bu alanlar doldurulduktan sonra, "Yön A mı B mi?" kararı verilip ilk haftanın işleri planlanır.
