import 'package:flutter/widgets.dart';

/// FiyatRadar i18n katmanı.
///
/// Flutter'ın arb-codegen yerine doğrudan Dart map'leri kullanıyoruz çünkü:
///   1. Build adımına ek dependency koymadan dil ekleyebiliyoruz.
///   2. Çevirileri kod inceleme akışında diff olarak görmek kolay.
///   3. Eksik anahtar olduğunda silently TR fallback dönüyor — production'da
///      görsel olarak boş etiket bırakmıyor.
///
/// Kullanım:
///   ```dart
///   final s = AppStrings.of(context);
///   Text(s.t('store.tab.bazaar'))
///   ```
///
/// Çağrı noktası context yoksa (örn. background callback) `AppStrings.tr(
/// locale, key)` direkt çağrılabilir.
class AppStrings {
  AppStrings(this.locale);

  final Locale locale;

  static AppStrings of(BuildContext context) {
    return AppStringsScope.of(context)?.strings ??
        AppStrings(const Locale('tr'));
  }

  /// `context` olmadan çevirmek için.
  static String trKey(Locale locale, String key) {
    final lang = _normalize(locale);
    return _table[key]?[lang] ?? _table[key]?['tr'] ?? key;
  }

  String t(String key) => trKey(locale, key);

  /// Argümanlı çeviri (örn. "%count% ürün").
  String f(String key, Map<String, Object> args) {
    var out = t(key);
    args.forEach((k, v) {
      out = out.replaceAll('%$k%', '$v');
    });
    return out;
  }

  static String _normalize(Locale locale) {
    final code = locale.languageCode.toLowerCase();
    return code == 'en' ? 'en' : 'tr';
  }

  /// Desteklenen diller.
  static const List<Locale> supportedLocales = [
    Locale('tr'),
    Locale('en'),
  ];

  /// String tablosu. Anahtar konvansiyonu:
  ///   `<alan>.<bağlam>.<son>` — örn. `store.tab.chains`.
  /// TR varsayılan; eksik EN olursa TR fallback.
  static const Map<String, Map<String, String>> _table = {
    // Common
    'common.save': {'tr': 'Kaydet', 'en': 'Save'},
    'common.update': {'tr': 'Güncelle', 'en': 'Update'},
    'common.cancel': {'tr': 'İptal', 'en': 'Cancel'},
    'common.delete': {'tr': 'Sil', 'en': 'Delete'},
    'common.edit': {'tr': 'Düzenle', 'en': 'Edit'},
    'common.add': {'tr': 'Ekle', 'en': 'Add'},
    'common.approve': {'tr': 'Onayla', 'en': 'Approve'},
    'common.reject': {'tr': 'Reddet', 'en': 'Reject'},
    'common.loading': {'tr': 'Yükleniyor…', 'en': 'Loading…'},
    'common.retry': {'tr': 'Tekrar dene', 'en': 'Retry'},
    'common.applyFilter': {'tr': 'Filtreyi uygula', 'en': 'Apply filter'},
    'common.filter': {'tr': 'FİLTRE', 'en': 'FILTER'},
    'common.active': {'tr': 'AKTİF', 'en': 'ACTIVE'},
    'common.passive': {'tr': 'PASİF', 'en': 'PASSIVE'},
    'common.deactivate': {'tr': 'Pasifle', 'en': 'Deactivate'},
    'common.activate': {'tr': 'Aktif et', 'en': 'Activate'},
    'common.required': {'tr': 'zorunlu', 'en': 'required'},
    'common.optional': {'tr': 'opsiyonel', 'en': 'optional'},
    'common.loadMore': {'tr': 'Daha fazla yükle', 'en': 'Load more'},
    'common.dismiss': {'tr': 'Vazgeç', 'en': 'Dismiss'},

    // Language picker
    'lang.title': {'tr': 'Dil', 'en': 'Language'},
    'lang.tr': {'tr': 'Türkçe', 'en': 'Turkish'},
    'lang.en': {'tr': 'İngilizce', 'en': 'English'},
    'lang.subtitle': {
      'tr': 'Uygulama arayüz dilini seç.',
      'en': 'Choose the app interface language.',
    },

    // Store admin (mağaza yönetimi)
    'store.title': {'tr': 'Mağaza', 'en': 'Store'},
    'store.titleTail': {'tr': ' yönetimi', 'en': ' management'},
    'store.overline': {'tr': 'ADMIN · MAĞAZA AĞI', 'en': 'ADMIN · STORE NETWORK'},
    'store.tab.chains': {'tr': 'Zincirler', 'en': 'Chains'},
    'store.tab.physical': {
      'tr': 'Fiziksel Mağazalar',
      'en': 'Physical Stores',
    },
    'store.tab.online': {'tr': 'Online Mağazalar', 'en': 'Online Stores'},
    'store.tab.bazaars': {
      'tr': 'Mahalle Pazarları',
      'en': 'Neighborhood Markets',
    },
    'store.tab.pending': {'tr': 'Onay Bekleyen', 'en': 'Pending Approval'},
    'store.tab.legacy': {'tr': 'Eski Kayıtlar', 'en': 'Legacy Records'},
    'store.empty.chains': {
      'tr': 'Henüz zincir kaydı yok.',
      'en': 'No chains yet.',
    },
    'store.empty.physical': {
      'tr': 'Henüz fiziksel mağaza/şube eklenmemiş.',
      'en': 'No physical stores yet.',
    },
    'store.empty.online': {
      'tr': 'Henüz online mağaza/kaynak eklenmemiş.',
      'en': 'No online stores yet.',
    },
    'store.empty.bazaars': {
      'tr': 'Henüz mahalle pazarı eklenmemiş.',
      'en': 'No neighborhood markets yet.',
    },
    'store.empty.pending': {
      'tr': 'Onay bekleyen kayıt yok.',
      'en': 'No records pending approval.',
    },
    'store.search.hint': {'tr': 'Mağaza ara', 'en': 'Search store'},
    'store.region.all': {'tr': 'Tüm bölgeler', 'en': 'All regions'},
    'store.region.allCities': {'tr': 'Tüm şehirler', 'en': 'All cities'},
    'store.region.allDistricts': {
      'tr': 'Tüm ilçeler',
      'en': 'All districts',
    },
    'store.region.waiting': {
      'tr': 'Bölge bekliyor',
      'en': 'Region pending',
    },
    'store.region.pickCityDistrict': {
      'tr': 'İl ve ilçe seç',
      'en': 'Pick city and district',
    },
    'store.region.required': {
      'tr': 'İl ve ilçe seçmen gerekli.',
      'en': 'City and district required.',
    },
    'store.type.all': {'tr': 'Tüm türler', 'en': 'All types'},
    'store.type.chain': {'tr': 'Zincir', 'en': 'Chain'},
    'store.type.local': {'tr': 'Yerel', 'en': 'Local'},
    'store.type.online': {'tr': 'Online', 'en': 'Online'},
    'store.type.bazaar': {'tr': 'Pazar', 'en': 'Bazaar'},
    'store.status.all': {'tr': 'Tüm statüler', 'en': 'All statuses'},
    'store.status.verified': {'tr': 'Doğrulandı', 'en': 'Verified'},
    'store.status.trusted': {'tr': 'Güvenilir', 'en': 'Trusted'},
    'store.status.pending': {'tr': 'Bekliyor', 'en': 'Pending'},
    'store.status.rejected': {'tr': 'Reddedildi', 'en': 'Rejected'},
    'store.chain.add': {'tr': 'Zincir ekle', 'en': 'Add chain'},
    'store.chain.edit': {'tr': 'Zincir düzenle', 'en': 'Edit chain'},
    'store.chain.supportsPhysical': {
      'tr': 'Fiziksel mağazaları destekler',
      'en': 'Supports physical stores',
    },
    'store.chain.supportsOnline': {
      'tr': 'Online kaynağı destekler',
      'en': 'Supports online source',
    },
    'store.chain.required': {
      'tr': 'Zincir adı gerekli.',
      'en': 'Chain name required.',
    },
    'store.chain.duplicate': {
      'tr': 'Bu zincir zaten kayıtlı.',
      'en': 'This chain is already registered.',
    },
    'store.chain.added': {'tr': 'Zincir eklendi.', 'en': 'Chain added.'},
    'store.chain.updated': {
      'tr': 'Zincir güncellendi.',
      'en': 'Chain updated.',
    },
    'store.place.addPhysical': {
      'tr': 'Fiziksel mağaza ekle',
      'en': 'Add physical store',
    },
    'store.place.addOnline': {
      'tr': 'Online mağaza ekle',
      'en': 'Add online store',
    },
    'store.place.edit': {'tr': 'Mağaza düzenle', 'en': 'Edit store'},
    'store.place.required': {
      'tr': 'Mağaza adı gerekli.',
      'en': 'Store name required.',
    },
    'store.place.chainFirst': {
      'tr': 'Önce zincir seç.',
      'en': 'Pick a chain first.',
    },
    'store.place.physicalRegion': {
      'tr': 'Fiziksel mağaza için il ve ilçe seç.',
      'en': 'Pick city and district for physical store.',
    },
    'store.place.added': {'tr': 'Mağaza eklendi.', 'en': 'Store added.'},
    'store.place.updated': {
      'tr': 'Mağaza güncellendi.',
      'en': 'Store updated.',
    },
    'store.place.displayName': {'tr': 'Görünen ad', 'en': 'Display name'},
    'store.place.address': {
      'tr': 'Adres (opsiyonel)',
      'en': 'Address (optional)',
    },
    'store.place.website': {'tr': 'Website URL', 'en': 'Website URL'},
    'store.place.deeplink': {
      'tr': 'App / deeplink (opsiyonel)',
      'en': 'App / deeplink (optional)',
    },
    'store.bazaar.add': {
      'tr': 'Mahalle pazarı ekle',
      'en': 'Add neighborhood market',
    },
    'store.bazaar.edit': {
      'tr': 'Mahalle pazarı düzenle',
      'en': 'Edit neighborhood market',
    },
    'store.bazaar.nameHint': {
      'tr': 'Pazar adı (örn. Salı Pazarı)',
      'en': 'Market name (e.g. Tuesday Market)',
    },
    'store.bazaar.required': {
      'tr': 'Pazar adı gerekli.',
      'en': 'Market name required.',
    },
    'store.bazaar.neighborhood': {
      'tr': 'Mahalle (opsiyonel)',
      'en': 'Neighborhood (optional)',
    },
    'store.bazaar.pickDay': {
      'tr': 'Pazar günü seç',
      'en': 'Pick market day',
    },
    'store.bazaar.added': {
      'tr': 'Mahalle pazarı eklendi.',
      'en': 'Neighborhood market added.',
    },
    'store.bazaar.updated': {
      'tr': 'Mahalle pazarı güncellendi.',
      'en': 'Neighborhood market updated.',
    },
    'store.bazaar.subtitle': {
      'tr': 'Pazar adı, il/ilçe, mahalle ve kurulduğu günü gir. Zincir gerekmez.',
      'en': 'Enter market name, city/district, neighborhood and the day it operates. No chain needed.',
    },
    'store.bazaar.submitNew': {'tr': 'Pazarı ekle', 'en': 'Add market'},

    // Days
    'day.monday': {'tr': 'Pazartesi', 'en': 'Monday'},
    'day.tuesday': {'tr': 'Salı', 'en': 'Tuesday'},
    'day.wednesday': {'tr': 'Çarşamba', 'en': 'Wednesday'},
    'day.thursday': {'tr': 'Perşembe', 'en': 'Thursday'},
    'day.friday': {'tr': 'Cuma', 'en': 'Friday'},
    'day.saturday': {'tr': 'Cumartesi', 'en': 'Saturday'},
    'day.sunday': {'tr': 'Pazar', 'en': 'Sunday'},

    // Paywall / Pro
    'pro.badge': {'tr': 'PRO', 'en': 'PRO'},
    'pro.upgradeCta': {
      'tr': 'Reklamsız deneyim için Pro\'ya geç',
      'en': 'Upgrade to Pro for an ad-free experience',
    },

    // Greetings
    'home.greeting.goodMorning': {'tr': 'Günaydın', 'en': 'Good morning'},
    'home.greeting.goodDay': {'tr': 'İyi günler', 'en': 'Good day'},
    'home.greeting.goodEvening': {'tr': 'İyi akşamlar', 'en': 'Good evening'},
    'home.greeting.goodNight': {'tr': 'İyi geceler', 'en': 'Good night'},
    'home.title.fallback': {'tr': 'Anasayfa', 'en': 'Home'},

    // Nav / dock labels
    'nav.home': {'tr': 'Anasayfa', 'en': 'Home'},
    'nav.explore': {'tr': 'Keşfet', 'en': 'Explore'},
    'nav.basket': {'tr': 'Sepet', 'en': 'Basket'},
    'nav.profile': {'tr': 'Profil', 'en': 'Profile'},

    // Add price tab
    'addPrice.overline': {
      'tr': 'TOPLULUĞA KATKI',
      'en': 'COMMUNITY CONTRIBUTION',
    },
    'addPrice.title': {'tr': 'Fiyat', 'en': 'Add'},
    'addPrice.titleTail': {'tr': ' ekle', 'en': ' price'},
    'addPrice.guest.title': {
      'tr': 'Fiyat eklemek için hesap aç',
      'en': 'Create an account to add prices',
    },
    'addPrice.guest.body': {
      'tr': 'Misafir hesaplar fiyat ekleyemez ve doğrulayamaz. '
          'Ücretsiz hesap açınca her katkı için puan kazanır, fiyat alarmı '
          'kurabilirsin.',
      'en': 'Guest accounts cannot add or verify prices. '
          'Create a free account to earn points for every contribution and '
          'set price alerts.',
    },
    'addPrice.guest.cta': {'tr': 'Ücretsiz üye ol', 'en': 'Sign up free'},

    // Basket tab
    'basket.overline': {'tr': 'TOPLUCA SORGULA', 'en': 'COMPARE TOGETHER'},
    'basket.title': {'tr': 'Sepet', 'en': 'Basket'},
    'basket.description': {
      'tr': 'Bölgende bildirilen fiyatlara göre tahmini sepet planını karşılaştır.',
      'en': 'Compare your estimated basket using prices reported in your area.',
    },
    'basket.tab.mine': {'tr': 'Sepetim', 'en': 'My basket'},
    'basket.tab.compare': {'tr': 'Karşılaştır', 'en': 'Compare'},
    'basket.guest.pill': {
      'tr': 'Misafir hesap · %remaining% / %limit% karşılaştırma kaldı. Üye ol, sınırsız hesapla.',
      'en': 'Guest account · %remaining% / %limit% comparisons left. Sign up for unlimited.',
    },
    'basket.guest.limitTitle': {
      'tr': 'Misafir limiti doldu',
      'en': 'Guest limit reached',
    },
    'basket.guest.limitBody': {
      'tr': 'Misafir hesaplar 3 sepet karşılaştırması yapabilir. Ücretsiz üye olunca sınırsız hesap, fiyat alarmı ve katkı puanı kazanma açılır.',
      'en': 'Guests can run 3 basket comparisons. Sign up free for unlimited comparisons, price alerts, and contribution points.',
    },
    'basket.guest.signupCta': {'tr': 'Ücretsiz üye ol', 'en': 'Sign up free'},
    'basket.guest.proCta': {'tr': 'Pro\'ya geç', 'en': 'Upgrade to Pro'},

    // Profile tab
    'profile.overline': {'tr': 'HESABIN', 'en': 'YOUR ACCOUNT'},
    'profile.title': {'tr': 'Profil', 'en': 'Profile'},
    'profile.guest.label': {'tr': 'Misafir', 'en': 'Guest'},
    'profile.signUp': {'tr': 'Üye ol', 'en': 'Sign up'},
    'profile.signIn': {'tr': 'Giriş yap', 'en': 'Sign in'},
    'profile.signOut': {'tr': 'Çıkış yap', 'en': 'Sign out'},
    'profile.settings': {'tr': 'Ayarlar', 'en': 'Settings'},
    'profile.language': {'tr': 'Dil', 'en': 'Language'},
    'profile.notifications': {'tr': 'Bildirimler', 'en': 'Notifications'},
    'profile.region': {'tr': 'Bölge', 'en': 'Region'},
    'profile.watchlist': {'tr': 'Takip listem', 'en': 'My watchlist'},

    // Explore tab
    'explore.overline': {'tr': 'KEŞFET', 'en': 'EXPLORE'},
    'explore.title': {'tr': 'Katalog', 'en': 'Catalog'},
    'explore.search.hint': {
      'tr': 'Ürün, marka veya kategori ara',
      'en': 'Search product, brand or category',
    },
    'explore.empty': {
      'tr': 'Sonuç bulunamadı.',
      'en': 'No results found.',
    },
    'explore.filter.all': {'tr': 'Tümü', 'en': 'All'},

    // Vote / verify on price entry
    'vote.up': {'tr': 'Doğru', 'en': 'Correct'},
    'vote.down': {'tr': 'Yanlış', 'en': 'Wrong'},
    'vote.blocked.signIn': {
      'tr': 'Oy vermek için giriş yap.',
      'en': 'Sign in to vote.',
    },
    'vote.blocked.guest': {
      'tr': 'Doğrulama için ücretsiz hesap aç.',
      'en': 'Create a free account to verify.',
    },
    'vote.blocked.own': {
      'tr': 'Kendi girdiğin fiyata oy veremezsin.',
      'en': "You can't vote on a price you reported.",
    },
    'vote.blocked.already': {
      'tr': 'Bu fiyata zaten oy verdin.',
      'en': 'You already voted on this price.',
    },

    // Auth / login
    'auth.welcome': {'tr': 'Hoş geldin', 'en': 'Welcome'},
    'auth.email': {'tr': 'E-posta', 'en': 'Email'},
    'auth.password': {'tr': 'Şifre', 'en': 'Password'},
    'auth.signUp': {'tr': 'Üye ol', 'en': 'Sign up'},
    'auth.signIn': {'tr': 'Giriş yap', 'en': 'Sign in'},
    'auth.signInGoogle': {'tr': 'Google ile devam et', 'en': 'Continue with Google'},
    'auth.continueAsGuest': {
      'tr': 'Misafir olarak devam et',
      'en': 'Continue as guest',
    },
    'auth.guestDisclaimer': {
      'tr': 'Misafir olarak fiyatları görebilir, sepet karşılaştırabilirsin. '
          'Fiyat eklemek veya puan kazanmak için hesap aç.',
      'en': 'As a guest you can browse prices and compare baskets. '
          'Sign up to add prices and earn points.',
    },

    // Add to cart / Watchlist / Alerts (product detail)
    'product.addToCart': {'tr': 'Sepete ekle', 'en': 'Add to basket'},
    'product.priceAlert': {'tr': 'Fiyat alarmı', 'en': 'Price alert'},
    'product.report': {'tr': 'Raporla', 'en': 'Report'},
    'product.firstPriceCta': {
      'tr': 'İlk fiyatı sen ekleyebilirsin',
      'en': 'You can add the first price',
    },

    // ── Settings hub ──────────────────────────────────────────────────────────
    'settings.overline': {'tr': 'GENEL', 'en': 'GENERAL'},
    'settings.title': {'tr': 'Ayarlar', 'en': 'Settings'},
    'settings.section.account': {'tr': 'HESAP', 'en': 'ACCOUNT'},
    'settings.section.notifications': {
      'tr': 'BİLDİRİMLER',
      'en': 'NOTIFICATIONS',
    },
    'settings.section.app': {'tr': 'UYGULAMA', 'en': 'APP'},
    'settings.section.helpLegal': {
      'tr': 'YARDIM VE YASAL',
      'en': 'HELP & LEGAL',
    },
    'settings.profileInfo': {'tr': 'Profil bilgileri', 'en': 'Profile details'},
    'settings.profileInfo.sub': {
      'tr': 'Ad, kullanıcı adı, telefon',
      'en': 'Name, username, phone',
    },
    'settings.account': {'tr': 'Hesap', 'en': 'Account'},
    'settings.account.sub': {
      'tr': 'E-posta doğrulama, hesap silme',
      'en': 'Email verification, account deletion',
    },
    'settings.contributions': {'tr': 'Katkılarım', 'en': 'My contributions'},
    'settings.contributions.sub': {
      'tr': 'Paylaştığın fiyatlar',
      'en': 'Prices you shared',
    },
    'settings.notificationPrefs': {
      'tr': 'Bildirim tercihleri',
      'en': 'Notification preferences',
    },
    'settings.notificationPrefs.sub': {
      'tr': 'Push, fiyat alarmı ve haftalık özet',
      'en': 'Push, price alerts and weekly summary',
    },
    'settings.myAlerts': {'tr': 'Fiyat alarmlarım', 'en': 'My price alerts'},
    'settings.myAlerts.sub': {
      'tr': 'Takip ettiğin ürün alarmları',
      'en': 'Product alerts you follow',
    },
    'settings.languageRow': {'tr': 'Dil / Language', 'en': 'Language / Dil'},
    'settings.releaseNotes': {
      'tr': 'Güncelleme geçmişi',
      'en': 'Release notes',
    },
    'settings.releaseNotes.sub': {
      'tr': 'Yeni özellik ve düzeltmeler',
      'en': 'New features and fixes',
    },
    'settings.helpFaq': {'tr': 'Yardım ve SSS', 'en': 'Help & FAQ'},
    'settings.helpFaq.sub': {
      'tr': 'Nasıl çalışır, güven, puan, alarm',
      'en': 'How it works, trust, points, alerts',
    },
    'settings.contactSupport': {
      'tr': 'İletişim ve Destek',
      'en': 'Contact & support',
    },
    'settings.contactSupport.sub': {
      'tr': 'Soru, öneri, geri bildirim',
      'en': 'Questions, suggestions, feedback',
    },
    'settings.about': {'tr': 'Hakkında', 'en': 'About'},
    'settings.about.sub': {
      'tr': 'Sürüm ve yasal metinler',
      'en': 'Version and legal texts',
    },
    'settings.backToExplore': {'tr': 'Keşfe dön', 'en': 'Back to explore'},

    // ── Notification preferences ───────────────────────────────────────────────
    'notifPrefs.overline': {'tr': 'RADAR SİNYALLERİ', 'en': 'RADAR SIGNALS'},
    'notifPrefs.title': {'tr': 'Bildirim tercihleri', 'en': 'Notification preferences'},
    'notifPrefs.push': {'tr': 'Push bildirimler', 'en': 'Push notifications'},
    'notifPrefs.push.sub': {
      'tr': 'Uygulamaya canlı sinyal gelsin',
      'en': 'Get live signals in the app',
    },
    'notifPrefs.priceAlerts': {'tr': 'Fiyat alarmları', 'en': 'Price alerts'},
    'notifPrefs.priceAlerts.sub': {
      'tr': 'Takip ettiğin ürünün fiyatı düştüğünde veya yükseldiğinde haber al',
      'en': 'Get notified when a product you follow goes up or down',
    },
    'notifPrefs.regional': {
      'tr': 'Bölgesel fiyat hareketleri',
      'en': 'Regional price moves',
    },
    'notifPrefs.regional.sub': {
      'tr': 'Bölgendeki bir markette fiyat düştüğünde / yükseldiğinde push gelsin',
      'en': 'Get a push when a store near you drops or raises a price',
    },
    'notifPrefs.verifications': {
      'tr': 'Doğrulama bildirimleri',
      'en': 'Verification notifications',
    },
    'notifPrefs.verifications.sub': {
      'tr': 'Eklediğin fiyat topluluk tarafından doğrulandığında veya reddedildiğinde haber al',
      'en': 'Get notified when a price you added is verified or rejected',
    },
    'notifPrefs.weekly': {'tr': 'Haftalık özet', 'en': 'Weekly summary'},
    'notifPrefs.weekly.proSub': {
      'tr': 'Haftalık fiyat hareketlerini ve fırsatları Bildirim Merkezi’nde gör.',
      'en': 'See weekly price moves and deals in your Notification Center.',
    },
    'notifPrefs.weekly.freeSub': {
      'tr': 'Pro ile haftalık fiyat özetlerini al.',
      'en': 'Get weekly price summaries with Pro.',
    },
    'notifPrefs.weekly.on': {
      'tr': 'Haftalık özet açıldı.',
      'en': 'Weekly summary turned on.',
    },
    'notifPrefs.weekly.off': {
      'tr': 'Haftalık özet kapatıldı.',
      'en': 'Weekly summary turned off.',
    },

    // ── Notification center ─────────────────────────────────────────────────────
    'notifCenter.overline': {'tr': 'RADAR SİNYALLERİ', 'en': 'RADAR SIGNALS'},
    'notifCenter.title': {'tr': 'Bildirim', 'en': 'Notification'},
    'notifCenter.titleTail': {'tr': ' merkezi', 'en': ' center'},
    'notifCenter.markAllRead': {
      'tr': 'Tümünü okundu işaretle',
      'en': 'Mark all as read',
    },
    'notifCenter.clearAll': {'tr': 'Tümünü sil', 'en': 'Clear all'},
    'notifCenter.filter.all': {'tr': 'Tümü', 'en': 'All'},
    'notifCenter.filter.unread': {'tr': 'Okunmamış', 'en': 'Unread'},
    'notifCenter.empty.title': {'tr': 'Henüz sinyal yok', 'en': 'No signals yet'},
    'notifCenter.empty.desc': {
      'tr': 'Fiyat alarmların ve radar bildirimleri burada görünür.',
      'en': 'Your price alerts and radar signals will show up here.',
    },
    'notifCenter.permissionBlocked': {
      'tr': 'Bildirim izni kapalı. Fiyat alarmlarını almak için bildirimlere izin ver.',
      'en': 'Notifications are off. Allow notifications to receive price alerts.',
    },
    'notifCenter.deleted': {'tr': 'Bildirim silindi', 'en': 'Notification deleted'},
    'notifCenter.deleteFailed': {
      'tr': 'Bildirim silinemedi. Lütfen tekrar dene.',
      'en': 'Could not delete the notification. Please try again.',
    },
    'notifCenter.clearAll.title': {
      'tr': 'Tüm bildirimleri sil',
      'en': 'Delete all notifications',
    },
    'notifCenter.clearAll.confirm': {
      'tr': 'Tüm bildirimleri silmek istiyor musun? Bu işlem geri alınamaz.',
      'en': 'Do you want to delete all notifications? This cannot be undone.',
    },
    'notifCenter.clearAll.done': {
      'tr': 'Tüm bildirimler silindi',
      'en': 'All notifications deleted',
    },
    'notifCenter.clearAll.failed': {
      'tr': 'Bildirimler silinemedi. Lütfen tekrar dene.',
      'en': 'Could not delete notifications. Please try again.',
    },
    'notifCenter.time.now': {'tr': 'şimdi', 'en': 'now'},
  };
}

/// Tüm widget ağacında [AppStrings] erişimi sağlar.
class AppStringsScope extends InheritedWidget {
  const AppStringsScope({
    super.key,
    required this.strings,
    required super.child,
  });

  final AppStrings strings;

  static AppStringsScope? of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<AppStringsScope>();
  }

  @override
  bool updateShouldNotify(AppStringsScope oldWidget) {
    return strings.locale != oldWidget.strings.locale;
  }
}
