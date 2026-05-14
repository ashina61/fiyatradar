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
