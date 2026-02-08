class AppConstants {
  // App Info
  static const String appName = 'FiyatRadar';
  static const String appVersion = '1.0.0';
  static const String packageName = 'com.fiyatradar';

  // Firestore Collections
  static const String usersCollection = 'users';
  static const String productsCollection = 'products';
  static const String pricesCollection = 'prices';
  static const String commentsCollection = 'comments';
  static const String notificationsCollection = 'notifications';
  static const String bannersCollection = 'banners';

  // Points System
  static const int pointsForPriceEntry = 10;
  static const int pointsForPriceEntryWithPhoto = 20;
  static const int pointsForValidation = 5;
  static const int pointsForComment = 3;
  static const int pointsForReportPrice = 8;
  static const int pointsForDailyLogin = 2;
  static const int pointsForInvite = 50;

  // Badges
  static const Map<String, int> badges = {
    'Yeni Başlayan': 0,
    'Aktif Kullanıcı': 100,
    'Fiyat Avcısı': 500,
    'Güvenilir Kullanıcı': 1000,
    'Uzman': 2500,
    'Efsane': 5000,
  };

  // Categories
  static const List<String> categories = [
    'Gıda',
    'İçecek',
    'Temizlik',
    'Kişisel Bakım',
    'Elektronik',
    'Giyim',
    'Ev & Yaşam',
    'Bebek',
    'Pet',
    'Diğer',
  ];

  // Popular Stores
  static const List<String> popularStores = [
    'Migros',
    'CarrefourSA',
    'BİM',
    'A101',
    'ŞOK',
    'File',
    'Macro Center',
    'Metro',
    'Gratis',
    'Watsons',
    'LC Waikiki',
    'Koçtaş',
    'Teknosa',
    'MediaMarkt',
    'Diğer',
  ];

  // Image Settings
  static const int maxImageWidth = 1024;
  static const int maxImageHeight = 1024;
  static const int imageQuality = 85;
  static const int maxImagesPerPrice = 5;

  // Validation
  static const int minPriceValue = 1;
  static const int maxPriceValue = 1000000;
  static const int minProductNameLength = 2;
  static const int maxProductNameLength = 100;
  static const int minCommentLength = 3;
  static const int maxCommentLength = 500;

  // Search
  static const int searchHistoryLimit = 10;
  static const int searchDebounceMs = 300;

  // Pagination
  static const int productsPerPage = 20;
  static const int pricesPerPage = 10;
  static const int commentsPerPage = 20;
  static const int notificationsPerPage = 20;
}

class FirebaseErrorMessages {
  static String getErrorMessage(String code) {
    switch (code) {
      case 'user-not-found':
        return 'Bu e-posta adresiyle kayıtlı kullanıcı bulunamadı.';
      case 'wrong-password':
        return 'Yanlış şifre girdiniz.';
      case 'email-already-in-use':
        return 'Bu e-posta adresi zaten kullanımda.';
      case 'weak-password':
        return 'Şifre en az 6 karakter olmalıdır.';
      case 'invalid-email':
        return 'Geçersiz e-posta adresi.';
      case 'operation-not-allowed':
        return 'Bu işlem şu anda kullanılamıyor.';
      case 'too-many-requests':
        return 'Çok fazla deneme yaptınız. Lütfen daha sonra tekrar deneyin.';
      case 'network-request-failed':
        return 'İnternet bağlantınızı kontrol edin.';
      default:
        return 'Bir hata oluştu. Lütfen tekrar deneyin.';
    }
  }
}
