import 'package:flutter/widgets.dart';

class AppLocalizations {
  AppLocalizations(this.locale);

  final Locale locale;

  static AppLocalizations of(BuildContext context) {
    final result = Localizations.of<AppLocalizations>(context, AppLocalizations);
    assert(result != null, 'AppLocalizations bulunamadı.');
    return result!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  static const _localizedValues = <String, Map<String, String>>{
    'tr': {
      'profileTitle': 'Profil',
      'genericUser': 'FiyatRadar Kullanıcısı',
      'eliteContributor': 'Elite Katkıcı',
      'validatorBadge': 'Doğrulayıcı',
      'editProfile': 'Profili Düzenle',
      'trustScoreLabel': 'Güven Skoru',
      'monthlySavings': 'Aylık Tasarruf',
      'bestMarket': 'En iyi market',
      'streakLabel': 'Seri',
      'dayLabel': 'gün',
      'myPrices': 'Fiyatlarım',
      'myReceipts': 'Fişlerim',
      'favorites': 'Favoriler',
      'notifications': 'Bildirimler',
      'recentActivities': 'Son Aktiviteler',
      'priceVerifiedTitle': '✅ Fiyat doğrulandı',
      'priceVerifiedSubtitle': 'Gönderdiğin fiyat topluluk tarafından onaylandı.',
      'contributionGainedTitle': '🔥 Katkı kazanıldı',
      'contributionGainedSubtitle': 'Katkı puanın artmaya devam ediyor.',
      'reportReceivedTitle': '⚠️ Rapor alındı',
      'reportReceivedSubtitle': 'Bildirim incelendi, kalite akışı sürüyor.',
      'noActivity': 'Henüz aktivite yok.',
      'badgesTitle': 'Rozetler',
      'badgeValidator': 'Doğrulayıcı',
      'badgeValidatorDesc': 'Doğruluk gücü yüksek kullanıcı',
      'badgeHunter': 'Fiyat Avcısı',
      'badgeHunterDesc': 'Yeni fiyat eklemede hızlı',
      'badgeReliable': 'Güven Ustası',
      'badgeReliableDesc': 'Sürekli kaliteli katkı',
      'badgeCommunity': 'Topluluk Lideri',
      'badgeCommunityDesc': 'Kullanıcılara yön veren profil',
      'nextBadgeSuggestion': 'Sıradaki rozet için 3 doğrulama daha yap.',
      'noBadges': 'Rozet kazanmak için fiyat ekle.',
      'settings': 'Ayarlar',
      'darkMode': 'Karanlık Mod',
      'notificationSettings': 'Bildirim Ayarları',
      'security': 'Güvenlik',
      'adminPanel': 'Admin Paneli',
      'logout': 'Çıkış Yap',
      'fullName': 'Ad Soyad',
      'usernameOptional': 'Kullanıcı adı (opsiyonel)',
      'bioOptional': 'Bio (opsiyonel)',
      'cityOptional': 'Şehir (opsiyonel)',
      'cancel': 'Vazgeç',
      'save': 'Kaydet',
      'profileUpdated': 'Profil güncellendi.',
      'profileUpdateError': 'Profil güncellenemedi. Tekrar dene.'
    }
  };

  String _t(String key) => _localizedValues[locale.languageCode]![key] ?? '';

  String get profileTitle => _t('profileTitle');
  String get genericUser => _t('genericUser');
  String get eliteContributor => _t('eliteContributor');
  String get validatorBadge => _t('validatorBadge');
  String get editProfile => _t('editProfile');
  String get trustScoreLabel => _t('trustScoreLabel');
  String get monthlySavings => _t('monthlySavings');
  String get bestMarket => _t('bestMarket');
  String get streakLabel => _t('streakLabel');
  String get dayLabel => _t('dayLabel');
  String get myPrices => _t('myPrices');
  String get myReceipts => _t('myReceipts');
  String get favorites => _t('favorites');
  String get notifications => _t('notifications');
  String get recentActivities => _t('recentActivities');
  String get priceVerifiedTitle => _t('priceVerifiedTitle');
  String get priceVerifiedSubtitle => _t('priceVerifiedSubtitle');
  String get contributionGainedTitle => _t('contributionGainedTitle');
  String get contributionGainedSubtitle => _t('contributionGainedSubtitle');
  String get reportReceivedTitle => _t('reportReceivedTitle');
  String get reportReceivedSubtitle => _t('reportReceivedSubtitle');
  String get noActivity => _t('noActivity');
  String get badgesTitle => _t('badgesTitle');
  String get badgeValidator => _t('badgeValidator');
  String get badgeValidatorDesc => _t('badgeValidatorDesc');
  String get badgeHunter => _t('badgeHunter');
  String get badgeHunterDesc => _t('badgeHunterDesc');
  String get badgeReliable => _t('badgeReliable');
  String get badgeReliableDesc => _t('badgeReliableDesc');
  String get badgeCommunity => _t('badgeCommunity');
  String get badgeCommunityDesc => _t('badgeCommunityDesc');
  String get nextBadgeSuggestion => _t('nextBadgeSuggestion');
  String get noBadges => _t('noBadges');
  String get settings => _t('settings');
  String get darkMode => _t('darkMode');
  String get notificationSettings => _t('notificationSettings');
  String get security => _t('security');
  String get adminPanel => _t('adminPanel');
  String get logout => _t('logout');
  String get fullName => _t('fullName');
  String get usernameOptional => _t('usernameOptional');
  String get bioOptional => _t('bioOptional');
  String get cityOptional => _t('cityOptional');
  String get cancel => _t('cancel');
  String get save => _t('save');
  String get profileUpdated => _t('profileUpdated');
  String get profileUpdateError => _t('profileUpdateError');
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => locale.languageCode == 'tr';

  @override
  Future<AppLocalizations> load(Locale locale) async => AppLocalizations(locale);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}
