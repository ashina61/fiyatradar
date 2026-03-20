# Codex Prompt Şablonları

## 1) Fiyat Ekle ekranı için Firestore listeleme promptu

```text
Flutter ve Firebase Firestore kullanıyorum. 'Fiyat Ekle' ekranımda Firestore'daki ürünleri listelemeye çalışıyorum ancak veriler ekrana gelmiyor, listeleme çalışmıyor.

Bana Firestore'dan verileri doğru ve güvenli bir şekilde çeken bir StreamBuilder yapısı kur. Şu özelliklere sahip olsun:
- snapshot.hasError durumunda ekrana mantıklı bir hata mesajı bassın (böylece sorunun nerede olduğunu görebileyim).
- snapshot.connectionState == ConnectionState.waiting durumunda ortada bir CircularProgressIndicator dönsün.
- Veri boş geldiğinde (ürün yoksa) 'Ürün bulunamadı' yazan bir uyarı çıkarsın.
- Veri başarıyla geliyorsa, bunu bir ListView.builder içinde basit bir ListTile olarak göstersin.
- Koleksiyon adımın 'products' olduğunu varsayarak kodu yaz.
```

## 2) Profil kaydetme bug'ı için Firestore güncelleme promptu

```text
Flutter ve Firebase Firestore ile bir profil düzenleme ekranı yapıyorum. Şu anki 'Kaydet' butonumda bir mantık hatası var: Sadece profil fotoğrafını değiştirmek istediğimde, kullanıcı adını da güncellemeye çalışıyor. Kullanıcı adı değişmediği için de validasyona takılıyor veya hata veriyor.

Bana sadece 'değişen' verileri güncelleyen bir Firestore güncelleme fonksiyonu yaz. Kurallar şunlar:
- Bir Map<String, dynamic> updateData = {}; oluştur.
- Eğer yeni bir fotoğraf seçilmişse (File null değilse), fotoğrafı yükleyip URL'sini bu Map'e eklesin (profilFoto key'i ile).
- Eğer kullaniciAdiController.text, kullanıcının veritabanındaki mevcut kullanıcı adından farklıysa, bunu da Map'e eklesin (kullaniciAdi key'i ile).
- Sadece updateData boş değilse (isNotEmpty) Firestore'daki kullanıcı belgesine update() işlemi yapsın.
- Bu mantığı içeren asenkron profiliGuncelle fonksiyonunu temiz bir Dart koduyla yazar mısın?
```
