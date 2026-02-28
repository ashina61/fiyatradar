# Faz 1 Kalan Güvenlik/Test Sıralaması

Bu dosya `CODE_REVIEW_AUDIT.md` içindeki **Faz 1 (1-2 hafta)** kalemlerinden henüz tamamlanmamış güvenlik ve test işlerini öncelik sırasına koyar.

## Durum Özeti
- [x] Firebase config dosyalarını `.gitignore` kapsamına almak.
- [x] Hızlı kazanımların bir bölümünü tamamlamak (ölü kod, deprecated provider, auth DI).
- [x] Firebase Security Rules kapsamını güçlendirmek ve test etmek (rules + emulator + CI).
- [x] Kritik iş mantığı için unit testleri artırmak (devam ediyor).

---

## Öncelik Sırası (Security + Test)

### 1) Firestore güvenlik kuralları sertleştirme (P0)
**Hedef:** Client-side atlanabilir kontrollerin sunucu tarafında zorlanması.

- [x] `users` güncellemesinde normal kullanıcı için alan kısıtlaması.
- [x] `users` içinde `isAdmin/role/points/trust*` alanlarını normal kullanıcıya immutable yapmak.
- [x] `products` yazma işlemlerini admin ile sınırlandırmak.
- [x] `priceReports/comments` oluşturma/güncellemede sahiplik doğrulaması.
- [x] `adminActions` için yalnız admin + actor doğrulaması.
- [x] Catch-all deny (`/{document=**}`) ile varsayılan kapalı politika.

**Kabul kriteri:**
- Firebase Emulator üzerinde yetkisiz yazma girişimleri reddedilmeli.
- Admin olmayan kullanıcı `isAdmin=true` yazamamalı.

---

### 2) Security rules regresyon testleri (P0)
**Hedef:** Rule değişikliklerinin kırılmadan sürdürülebilmesi.

- [x] Emulator tabanlı rules test altyapısını ekle (`firebase emulators:exec` veya CI job).
- [x] Pozitif testler: owner create allowed, admin write allowed.
- [x] Negatif testler: owner privilege escalation denied, non-admin product write denied.

**Kabul kriteri:**
- En az 8 senaryoluk rule test seti.
- [x] PR pipeline’da otomatik çalıştırma.

---

### 3) Kritik domain unit testleri (P1)
**Hedef:** Auditte belirtilen düşük test kapsamını hızlıca artırmak.

- [x] Model serialization testleri (UserModel, PriceModel, ProductModel).
- [x] Sepet hesaplama servisinde sınır koşulları (indirim/eksik ürün/eşit fiyat).
- [x] Auth hata mesajı map’inin deterministik testleri.

**Kabul kriteri:**
- Yeni en az 10 unit test.
- Hatalı veri girdisi için en az 3 negatif test.

---

### 4) Kritik işlemleri server-side’a taşıma planı (P1)
**Hedef:** Puan/admin gibi suistimal riski yüksek işlemleri client’tan koparmak.

- [x] Cloud Functions backlog oluştur (`points`, `ban`, `adminAction`).
- [x] Her işlem için input şeması + yetki matrisi yaz.
- [x] Geçişte geriye uyumluluk planı belirle.

**Kabul kriteri:**
- Fonksiyon bazlı teknik tasarım dokümanı.
- Her endpoint için authz kuralı net tanımlı.

---

## Uygulama Notu
Bu PR ile rules sertleştirme + emulator test altyapısı + CI entegrasyonu tamamlandı. Sonraki adım senaryo sayısını artırıp kapsamı genişletmektir.
