# FiyatRadar Codebase Audit Report

## 1. Mimari ve Kod Kalitesi
- [KRİTİK] Profil alanında paralel kullanıcı modeli ve servis akışı var. `lib/models/user_model.dart` ile `lib/screens/profile/user_model.dart` aynı domain'i iki farklı şema ile temsil ediyor; buna ek olarak `lib/providers/profile_provider.dart` ve `lib/screens/profile/profile_service.dart` bu ikinci modeli kullanıyor. Bu yapı hem DRY ihlali oluşturuyor hem de profil ekranlarında yazılan alanların uygulamanın geri kalan modeliyle ayrışmasına neden oluyor.
- [UYARI] Riverpod kullanımı tutarsız. Bazı akışlar provider üzerinden yönetilirken (`lib/providers/auth_provider.dart`), bazı yerlerde `ChangeNotifierProvider.autoDispose` içinde manuel `ref.listen` ile yaşam döngüsü yönetiliyor (`lib/features/basket/basket_view_model.dart`). Bu hibrit yaklaşım test edilebilirliği ve state takibini zorlaştırıyor.
- [UYARI] Tema sistemi parçalı. `lib/main.dart` genel `ThemeData` tanımlıyor, `lib/screens/home/home_screen.dart` içinde ayrı `FRColors`, kart/sepet/puan ekranlarında ise başka premium palette sabitleri kullanılıyor. Tekil renk kaynakları yerine ekran bazlı paletler tasarım dilini kırıyor.
- [ÖNERİ] `lib/models/store.dart` ve `lib/models/store_model.dart` aynı iş alanı için iki farklı store modeli taşıyor. `lib/providers/add_price_provider.dart` ve `lib/providers/price_report_provider.dart` gibi katmanlar ikisini birlikte kullanıyor; mapper sayısı arttıkça hata olasılığı da artıyor.

## 2. Hata ve Mantık Boşlukları
- [KRİTİK] Firestore güvenlik kuralları ile istemci yazma payload'ları uyumsuz. Kullanıcı kendi dokümanında sadece `name`, `photoUrl`, `cityCode`, `cityName`, `city`, `savedProducts`, `lastLoginAt`, `fcmToken` alanlarını güncelleyebiliyor; ancak `lib/services/user_settings_repository.dart` kişisel bilgi kaydında `firstName`, `lastName`, `district`, `neighborhood`, `updatedAt` yazıyor ve bildirim tercihlerinde `notificationPrefs`, `alarmNotifications`, `campaignNotifications`, `badgeNotifications`, `updatedAt` yazıyor. Bu işlemler production'da permission-denied ile patlar.
- [KRİTİK] `lib/providers/profile_provider.dart` ve `lib/screens/profile/profile_service.dart` `screens/profile/user_model.dart` üzerindeki `toMap()/fromMap()` ile `surname`, `priceAlarm`, `campaignNotification`, `badgeNotification` alanlarını yazıyor; ancak global kullanıcı modeli farklı alan adları (`lastName`, `alarmNotifications`, `campaignNotifications`, `badgeNotifications`) kullanıyor. Bu veri tutarsızlığı profil verisinin farklı ekranlarda farklı görünmesine yol açar.
- [UYARI] `lib/services/auth_service.dart` kayıt akışında kullanıcı belgesine peş peşe iki ayrı `set` ve davet kodu varsa ilave `update` çağrıları yapıyor. Bu akış transaction olmadığı için yarım kalmış kullanıcı profili, eksik inviteCount/points veya eşzamanlı girişlerde tutarsız puan üretme riski taşıyor.
- [UYARI] `lib/services/location_service.dart` ters geocoding çıktısını `thoroughfare!`, `subLocality!`, `locality!`, `administrativeArea!` null assertion'ları ile kullanıyor. Geocoder bazı cihazlarda bu alanları boş döndürebildiği için servis seviyesinde crash riski var.
- [UYARI] `lib/features/basket/basket_view_model.dart` içinde `userId!` ile stream aboneliği açılıyor. Bugünkü akışta koruma var; ancak ileride eşzamanlı auth değişiminde veya provider yeniden kurulumunda null assertion doğrudan crash üretir.

## 3. Tasarım ve UI/UX Tutarlılığı
- [UYARI] `FRColors` yalnızca `lib/screens/home/home_screen.dart` içinde tanımlı; diğer ekranlar kendi `Color(0x...)` sabitleriyle ilerliyor. Özellikle profil ekranları ve onboarding'de çok sayıda hard-coded renk/padding/font değeri bulunuyor. Bu yapı Porsche DNA olarak tarif edilen premium dilin merkezi biçimde yönetilmesini engelliyor.
- [UYARI] `lib/widgets/badge_unlocked_overlay.dart` içindeki `width: 320` ve `lib/screens/onboarding/onboarding_screen.dart` içindeki `height: 320` gibi sabit ölçüler küçük cihazlarda taşma riski yaratıyor.
- [UYARI] `lib/screens/home/home_screen.dart` özet bölümünde `GridView.count(crossAxisCount: 2, childAspectRatio: 1.0)` kullanıyor. Yoğun metinli kartlarda split-screen, küçük Android cihazlar veya büyük yazı ölçeklerinde içerik sıkışabilir.
- [ÖNERİ] Home, profile ve points modülleri arasında farklı tipografi ve spacing sistemleri var. `AppSpacing` ve tema token'ları mevcut olan modüller referans alınarak tüm ekranların ortak design token setine taşınması gerekli.

## 4. Hukuki ve Güvenlik Riskleri
- [KRİTİK] Kayıt ekranında sadece bilgilendirici metin var; açık rıza/aydınlatma onayı için zorunlu checkbox, timestamp veya versiyon kaydı yok. `lib/screens/auth/register_screen.dart` kayıt öncesi KVKK/GDPR uyumlu açık onay toplamıyor.
- [UYARI] Uygulama içinde profil ve about ekranlarında gizlilik politikası / kullanım koşulları linkleri bulunuyor; ancak ilk kayıt akışında kullanıcıdan bunları ayrı ayrı açıp onaylaması istenmiyor. Yasal metin gösterimi ile hukuki ispat birbirine karıştırılmış durumda.
- [UYARI] Firestore kuralları temel koleksiyonlarda kapalı varsayılan yaklaşımı benimsediği için genel yapı güvenli; ancak kurallar ile istemci payload'ları uyuşmadığından ekip sahada bu kuralları gevşetmeye zorlanabilir. En büyük risk, business logic'i kurala göre değil istemciye göre şekillendirme eğilimi.
- [ÖNERİ] `fcmToken`, şehir/ilçe/mahalle ve profil bilgileri kişisel veri niteliğinde. Kod tabanında veri saklama süresi, silme/export akışı veya hesap silme prosedürü görünmüyor. KVKK/GDPR için retention ve deletion tasarımı eksik.

## 5. Optimizasyon ve Production Readiness
- [KRİTİK] Uygulama analiz/test altyapısı ortamda çalıştırılamadı; `flutter analyze` komutu hiç yok, Firestore rule testleri ise bağımlılık eksikliği / registry politikası nedeniyle ayağa kalkmadı. CI'da zorunlu statik analiz + emulator rule testleri olmadan mağaza yayını riskli.
- [UYARI] `lib/main.dart` içinde `Firebase.initializeApp()` hatası tamamen swallow ediliyor ve sadece bool flag set ediliyor. Başlangıç hataları için crash reporting, loglama ve geri kazanım akışı eksik.
- [UYARI] `lib/features/basket/basket_view_model.dart` sepette her kullanıcı değişiminde tüm ürün listesini `getAllProducts()` stream'i ile tekrar dinliyor. Büyük kataloglarda bu gereksiz veri çekimi ve yeniden render maliyeti yaratır.
- [ÖNERİ] `lib/providers/auth_provider.dart` içindeki `currentUserProvider`, `authStateProvider` sonucunu tekrar `when` ile çözerek ekstra async katman yaratıyor. Auth + user profile birleşik bir repository/provider ile sadeleştirilebilir.

## İlk 3 Acil Adım
1. Tek bir `UserModel` ve tek bir profil veri akışı belirleyin; `screens/profile/user_model.dart`, `profile_service.dart`, `profile_provider.dart` gibi paralel yapıları global domain modeline birleştirin.
2. `firestore.rules` ile istemci payload'larını hizalayın: ya izin verilen kullanıcı alanlarını kurallara ekleyin ya da istemci yazma payload'larını mevcut allow-list'e indirin; bunu emulator rule testleri ile güvenceye alın.
3. Kayıt akışına zorunlu KVKK/Gizlilik/Kullanım Koşulları onay checkbox'ları, onay versiyonu ve timestamp saklama mekanizması ekleyin; ardından auth/profile yazmalarını transaction veya callable backend akışına taşıyın.
