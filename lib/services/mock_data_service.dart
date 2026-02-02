import '../models/notification_model.dart';

class MockProduct {
  final String id;
  final String name;
  final String category;
  final double currentPrice;
  final double? oldPrice;
  final String store;
  final String? imageUrl;
  final DateTime addedAt;
  final bool isTrending;
  final bool isBestDeal;

  const MockProduct({
    required this.id,
    required this.name,
    required this.category,
    required this.currentPrice,
    this.oldPrice,
    required this.store,
    this.imageUrl,
    required this.addedAt,
    this.isTrending = false,
    this.isBestDeal = false,
  });

  double? get discountPercentage {
    if (oldPrice == null || oldPrice! <= currentPrice) return null;
    return ((oldPrice! - currentPrice) / oldPrice! * 100);
  }
}

class MockBanner {
  final String id;
  final String title;
  final String subtitle;
  final String? imageUrl;
  final int colorValue;
  final bool isActive;

  const MockBanner({
    required this.id,
    required this.title,
    required this.subtitle,
    this.imageUrl,
    required this.colorValue,
    this.isActive = true,
  });

  MockBanner copyWith({
    String? id,
    String? title,
    String? subtitle,
    String? imageUrl,
    int? colorValue,
    bool? isActive,
  }) {
    return MockBanner(
      id: id ?? this.id,
      title: title ?? this.title,
      subtitle: subtitle ?? this.subtitle,
      imageUrl: imageUrl ?? this.imageUrl,
      colorValue: colorValue ?? this.colorValue,
      isActive: isActive ?? this.isActive,
    );
  }
}

class MockCategory {
  final String name;
  final String iconName;

  const MockCategory({required this.name, required this.iconName});
}

class MockUser {
  final String displayName;
  final String email;
  final int points;
  final int notifications;
  final int priceEntries;
  final int verifications;
  final List<String> savedProducts;

  const MockUser({
    required this.displayName,
    this.email = 'demo@fiyatradar.com',
    required this.points,
    required this.notifications,
    this.priceEntries = 45,
    this.verifications = 120,
    this.savedProducts = const ['p1', 'p3', 'p5', 'p7'],
  });

  String get initial => displayName.isNotEmpty ? displayName[0].toUpperCase() : '?';
}

class MockDataService {
  static final MockDataService _instance = MockDataService._internal();
  factory MockDataService() => _instance;
  MockDataService._internal() {
    _products = List<MockProduct>.from(_defaultProducts);
    _stores = List<String>.from(_defaultStores);
    _categories = List<MockCategory>.from(_defaultCategories);
    _banners = List<MockBanner>.from(_defaultBanners);
  }

  MockUser get currentUser => const MockUser(
        displayName: 'Demo Kullanici',
        points: 1250,
        notifications: 3,
      );

  // Mutable lists for admin operations
  late final List<MockProduct> _products;
  late final List<String> _stores;
  late final List<MockCategory> _categories;
  late final List<MockBanner> _banners;

  int _productIdCounter = 11;
  int _bannerIdCounter = 4;

  List<MockCategory> get categories => List.unmodifiable(_categories);

  List<String> get stores => List.unmodifiable(_stores);

  List<MockBanner> get banners => List.unmodifiable(_banners);

  List<MockBanner> get activeBanners =>
      _banners.where((b) => b.isActive).toList();

  static const List<MockCategory> _defaultCategories = [
    MockCategory(name: 'Elektronik', iconName: 'devices'),
    MockCategory(name: 'Gida', iconName: 'restaurant'),
    MockCategory(name: 'Temizlik', iconName: 'cleaning_services'),
    MockCategory(name: 'Kisisel Bakim', iconName: 'face'),
    MockCategory(name: 'Ev & Yasam', iconName: 'home'),
    MockCategory(name: 'Giyim', iconName: 'checkroom'),
    MockCategory(name: 'Spor', iconName: 'sports'),
    MockCategory(name: 'Oyuncak', iconName: 'toys'),
    MockCategory(name: 'Kitap', iconName: 'book'),
    MockCategory(name: 'Otomotiv', iconName: 'directions_car'),
  ];

  static const List<String> _defaultStores = [
    'Trendyol',
    'Hepsiburada',
    'Migros',
    'A101',
    'Boyner',
    'Watsons',
    'MediaMarkt',
    'Toyzz Shop',
    'Amazon',
    'D&R',
  ];

  static const List<MockBanner> _defaultBanners = [
    MockBanner(
      id: 'b1',
      title: 'Haftalik En Iyi Firsatlar',
      subtitle: '%50\'ye varan indirimler seni bekliyor!',
      colorValue: 0xFF6366F1,
    ),
    MockBanner(
      id: 'b2',
      title: 'Elektronik Festivali',
      subtitle: 'Teknoloji urunlerinde buyuk kampanya',
      colorValue: 0xFF10B981,
    ),
    MockBanner(
      id: 'b3',
      title: 'Fiyat Dustu Bildirimi',
      subtitle: 'Takip ettigin urunler ucuzladi!',
      colorValue: 0xFFF59E0B,
    ),
  ];

  static final List<MockProduct> _defaultProducts = [
    MockProduct(
      id: 'p1',
      name: 'Apple iPhone 15 Pro 256GB',
      category: 'Elektronik',
      currentPrice: 64999.00,
      oldPrice: 74999.00,
      store: 'Trendyol',
      addedAt: DateTime.now().subtract(const Duration(hours: 2)),
      isTrending: true,
      isBestDeal: true,
    ),
    MockProduct(
      id: 'p2',
      name: 'Samsung Galaxy S24 Ultra',
      category: 'Elektronik',
      currentPrice: 57999.00,
      oldPrice: 64999.00,
      store: 'Hepsiburada',
      addedAt: DateTime.now().subtract(const Duration(hours: 5)),
      isTrending: true,
      isBestDeal: true,
    ),
    MockProduct(
      id: 'p3',
      name: 'Ariel Sivi Camasir Deterjani 4L',
      category: 'Temizlik',
      currentPrice: 249.90,
      oldPrice: 349.90,
      store: 'Migros',
      addedAt: DateTime.now().subtract(const Duration(hours: 1)),
      isTrending: true,
      isBestDeal: true,
    ),
    MockProduct(
      id: 'p4',
      name: 'Nutella 750g',
      category: 'Gida',
      currentPrice: 89.90,
      oldPrice: 109.90,
      store: 'A101',
      addedAt: DateTime.now().subtract(const Duration(hours: 3)),
      isTrending: true,
    ),
    MockProduct(
      id: 'p5',
      name: 'Nike Air Max 270 React',
      category: 'Giyim',
      currentPrice: 3299.00,
      oldPrice: 4499.00,
      store: 'Boyner',
      addedAt: DateTime.now().subtract(const Duration(hours: 6)),
      isTrending: true,
      isBestDeal: true,
    ),
    MockProduct(
      id: 'p6',
      name: 'Oral-B Vitality Pro Elektrikli Dis Fircasi',
      category: 'Kisisel Bakim',
      currentPrice: 699.00,
      oldPrice: 899.00,
      store: 'Watsons',
      addedAt: DateTime.now().subtract(const Duration(minutes: 30)),
      isTrending: true,
    ),
    MockProduct(
      id: 'p7',
      name: 'Dyson V15 Detect Supurge',
      category: 'Ev & Yasam',
      currentPrice: 27999.00,
      oldPrice: 32999.00,
      store: 'MediaMarkt',
      addedAt: DateTime.now().subtract(const Duration(hours: 8)),
      isBestDeal: true,
    ),
    MockProduct(
      id: 'p8',
      name: 'Lego Technic Ferrari 488 GTE',
      category: 'Oyuncak',
      currentPrice: 1299.00,
      oldPrice: 1599.00,
      store: 'Toyzz Shop',
      addedAt: DateTime.now().subtract(const Duration(hours: 4)),
      isBestDeal: true,
    ),
    MockProduct(
      id: 'p9',
      name: 'Sony WH-1000XM5 Kulaklik',
      category: 'Elektronik',
      currentPrice: 8499.00,
      oldPrice: 10999.00,
      store: 'Amazon',
      addedAt: DateTime.now().subtract(const Duration(minutes: 45)),
      isTrending: true,
    ),
    MockProduct(
      id: 'p10',
      name: 'Istiklal Savaslari - Ilber Ortayli',
      category: 'Kitap',
      currentPrice: 79.00,
      oldPrice: 99.00,
      store: 'D&R',
      addedAt: DateTime.now().subtract(const Duration(hours: 12)),
    ),
  ];

  List<MockProduct> get products => List.unmodifiable(_products);

  List<MockProduct> get trendingProducts =>
      _products.where((p) => p.isTrending).toList();

  List<MockProduct> get bestDeals =>
      _products.where((p) => p.isBestDeal).toList();

  List<MockProduct> get recentProducts {
    final sorted = List<MockProduct>.from(_products)
      ..sort((a, b) => b.addedAt.compareTo(a.addedAt));
    return sorted.take(5).toList();
  }

  List<MockProduct> get savedProducts {
    final savedIds = currentUser.savedProducts;
    return _products.where((p) => savedIds.contains(p.id)).toList();
  }

  // Admin operations - Products

  void addProduct({
    required String name,
    required String category,
    String? description,
    String? barcode,
  }) {
    _products.add(MockProduct(
      id: 'p${_productIdCounter++}',
      name: name,
      category: category,
      currentPrice: 0.0,
      store: _stores.isNotEmpty ? _stores.first : 'Bilinmiyor',
      addedAt: DateTime.now(),
    ));
  }

  void removeProduct(String id) {
    _products.removeWhere((p) => p.id == id);
  }

  // Admin operations - Stores

  void addStore(String name) {
    if (!_stores.contains(name)) {
      _stores.add(name);
    }
  }

  void removeStore(String name) {
    _stores.remove(name);
  }

  // Admin operations - Categories

  void addCategory(String name) {
    if (!_categories.any((c) => c.name == name)) {
      _categories.add(MockCategory(name: name, iconName: 'category'));
    }
  }

  void removeCategory(String name) {
    _categories.removeWhere((c) => c.name == name);
  }

  // Admin operations - Banners

  void addBanner({
    required String title,
    required String subtitle,
    required int colorValue,
    String? imageUrl,
  }) {
    _banners.add(MockBanner(
      id: 'b${_bannerIdCounter++}',
      title: title,
      subtitle: subtitle,
      colorValue: colorValue,
      imageUrl: imageUrl,
    ));
  }

  void updateBanner(String id, {String? title, String? subtitle, int? colorValue, bool? isActive, String? imageUrl}) {
    final index = _banners.indexWhere((b) => b.id == id);
    if (index != -1) {
      _banners[index] = _banners[index].copyWith(
        title: title,
        subtitle: subtitle,
        colorValue: colorValue,
        isActive: isActive,
        imageUrl: imageUrl,
      );
    }
  }

  void removeBanner(String id) {
    _banners.removeWhere((b) => b.id == id);
  }

  void toggleBannerActive(String id) {
    final index = _banners.indexWhere((b) => b.id == id);
    if (index != -1) {
      _banners[index] = _banners[index].copyWith(isActive: !_banners[index].isActive);
    }
  }

  int get totalPriceEntries => _products.length * 3; // mock: ~3 prices per product

  List<NotificationModel> get notifications => [
        NotificationModel(
          id: 'n1',
          userId: 'demo',
          type: NotificationType.priceDropped,
          title: 'Fiyat Dustu!',
          body: 'Apple iPhone 15 Pro 256GB urunun fiyati 74.999 TL\'den 64.999 TL\'ye dustu.',
          productId: 'p1',
          productName: 'Apple iPhone 15 Pro 256GB',
          isRead: false,
          createdAt: DateTime.now().subtract(const Duration(minutes: 30)),
        ),
        NotificationModel(
          id: 'n2',
          userId: 'demo',
          type: NotificationType.priceDropped,
          title: 'Fiyat Dustu!',
          body: 'Samsung Galaxy S24 Ultra urunun fiyati 64.999 TL\'den 57.999 TL\'ye dustu.',
          productId: 'p2',
          productName: 'Samsung Galaxy S24 Ultra',
          isRead: false,
          createdAt: DateTime.now().subtract(const Duration(hours: 2)),
        ),
        NotificationModel(
          id: 'n3',
          userId: 'demo',
          type: NotificationType.newBadge,
          title: 'Yeni Basarim Kazandiniz!',
          body: 'Tebrikler! "Fiyat Avcisi" rozetini kazandiniz. 10 urunun fiyatini basariyla takip ettiniz.',
          isRead: false,
          createdAt: DateTime.now().subtract(const Duration(hours: 5)),
        ),
        NotificationModel(
          id: 'n4',
          userId: 'demo',
          type: NotificationType.priceVerified,
          title: 'Yeni Fiyat Eklendi',
          body: 'Sony WH-1000XM5 Kulaklik icin yeni bir fiyat bilgisi eklendi: 8.499 TL',
          productId: 'p9',
          productName: 'Sony WH-1000XM5 Kulaklik',
          isRead: true,
          createdAt: DateTime.now().subtract(const Duration(hours: 8)),
        ),
        NotificationModel(
          id: 'n5',
          userId: 'demo',
          type: NotificationType.system,
          title: 'Hosgeldiniz!',
          body: 'FiyatRadar\'a hosgeldiniz! Urunleri takip ederek fiyat dususlerinden aninda haberdar olun.',
          isRead: true,
          createdAt: DateTime.now().subtract(const Duration(days: 1)),
        ),
        NotificationModel(
          id: 'n6',
          userId: 'demo',
          type: NotificationType.priceDropped,
          title: 'Fiyat Dustu!',
          body: 'Nike Air Max 270 React urunun fiyati 4.499 TL\'den 3.299 TL\'ye dustu.',
          productId: 'p5',
          productName: 'Nike Air Max 270 React',
          isRead: true,
          createdAt: DateTime.now().subtract(const Duration(days: 2)),
        ),
        NotificationModel(
          id: 'n7',
          userId: 'demo',
          type: NotificationType.newBadge,
          title: 'Yeni Basarim Kazandiniz!',
          body: '"Erken Kus" rozetini kazandiniz. Ilk fiyat bildiriminizi basariyla gonderdiniz!',
          isRead: true,
          createdAt: DateTime.now().subtract(const Duration(days: 3)),
        ),
        NotificationModel(
          id: 'n8',
          userId: 'demo',
          type: NotificationType.system,
          title: 'Yeni Ozellik: Barkod Tarama',
          body: 'Artik urunleri barkod tarayarak hizlica ekleyebilirsiniz. Hemen deneyin!',
          isRead: true,
          createdAt: DateTime.now().subtract(const Duration(days: 5)),
        ),
        NotificationModel(
          id: 'n9',
          userId: 'demo',
          type: NotificationType.priceVerified,
          title: 'Yeni Fiyat Eklendi',
          body: 'Dyson V15 Detect Supurge icin yeni bir fiyat bilgisi eklendi: 27.999 TL',
          productId: 'p7',
          productName: 'Dyson V15 Detect Supurge',
          isRead: true,
          createdAt: DateTime.now().subtract(const Duration(days: 4)),
        ),
      ];
}
