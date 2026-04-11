import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/widgets.dart';

import '../models/product.dart';
import '../services/firebase_service.dart';

/// Points awarded for different actions in the rewards system.
class PointsRules {
  static const int addPrice = 10;
  static const int addProduct = 25;
  static const int favorite = 2;
  static const int dailyLogin = 5;

  /// 100 puan = ₺5 indirim
  static const double pointValueTl = 0.05;
}

class AppState extends ChangeNotifier {
  AppState();

  final FirebaseService _svc = FirebaseService.instance;

  // Auth
  User? user;

  // Catalog
  final List<Product> products = [];
  final List<AppBanner> banners = [];

  // User data (from Firestore user doc)
  Set<String> favorites = <String>{};
  int points = 0;
  int pointsToRedeem = 0; // local, user-chosen redemption
  final List<CartItem> cart = [];
  String displayName = 'Kahve Avcısı';
  String username = '@fiyatradar_user';
  String? phoneNumber;

  bool pushNotificationsEnabled = true;
  bool priceAlertsEnabled = true;
  bool weeklySummaryEnabled = true;
  bool twoFactorEnabled = false;
  bool biometricEnabled = true;

  final List<String> categories = const [
    'Tümü',
    'Kahvaltılık',
    'Meyve & Sebze',
    'İçecek',
    'Atıştırmalık',
    'Süt Ürünleri',
    'Temizlik',
  ];

  final List<String> stores = const [
    'A101',
    'BİM',
    'ŞOK',
    'Migros',
    'CarrefourSA',
    'Tarım Kredi',
  ];

  StreamSubscription? _productsSub;
  StreamSubscription? _bannersSub;
  StreamSubscription? _userSub;
  StreamSubscription? _notificationsSub;
  StreamSubscription? _productAlertsSub;
  bool _initialized = false;
  bool get initialized => _initialized;
  final List<AppNotification> notifications = [];
  final Map<String, ProductAlert> productAlerts = {};
  int get unreadNotificationCount =>
      notifications.where((n) => !n.isRead).length;

  Future<void> init() async {
    user = await _svc.ensureSignedIn();
    await _svc.bootstrap();

    _productsSub = _svc.products.snapshots().listen((snap) {
      products
        ..clear()
        ..addAll(snap.docs.map(Product.fromDoc));
      _reconcileCartProducts();
      notifyListeners();
    });

    _bannersSub = _svc.banners
        .where('isActive', isEqualTo: true)
        .snapshots()
        .listen((snap) {
      banners
        ..clear()
        ..addAll(snap.docs.map(AppBanner.fromDoc));
      banners.sort((a, b) => a.order.compareTo(b.order));
      notifyListeners();
    });

    // Ensure user doc exists
    final uref = _svc.userDoc(user!.uid);
    final udoc = await uref.get();
    if (!udoc.exists) {
      await uref.set({
        'displayName': displayName,
        'username': username,
        'points': 0,
        'favorites': <String>[],
        'cart': <Map<String, dynamic>>[],
        'settings': {
          'notifications': {
            'pushEnabled': pushNotificationsEnabled,
            'priceAlertsEnabled': priceAlertsEnabled,
            'weeklySummaryEnabled': weeklySummaryEnabled,
          },
          'security': {
            'twoFactorEnabled': twoFactorEnabled,
            'biometricEnabled': biometricEnabled,
          },
        },
        'createdAt': FieldValue.serverTimestamp(),
      });
    }
    _userSub = uref.snapshots().listen((snap) {
      final m = snap.data() ?? <String, dynamic>{};
      displayName = (m['displayName'] as String?)?.trim().isNotEmpty == true
          ? (m['displayName'] as String)
          : 'Kahve Avcısı';
      username = (m['username'] as String?)?.trim().isNotEmpty == true
          ? (m['username'] as String)
          : '@fiyatradar_user';
      phoneNumber = (m['phoneNumber'] as String?)?.trim().isNotEmpty == true
          ? (m['phoneNumber'] as String)
          : null;
      points = (m['points'] as num?)?.toInt() ?? 0;
      favorites = ((m['favorites'] as List?) ?? [])
          .map((e) => e.toString())
          .toSet();
      final settings = Map<String, dynamic>.from(
        (m['settings'] as Map?) ?? const <String, dynamic>{},
      );
      final notificationsSettings = Map<String, dynamic>.from(
        (settings['notifications'] as Map?) ?? const <String, dynamic>{},
      );
      final securitySettings = Map<String, dynamic>.from(
        (settings['security'] as Map?) ?? const <String, dynamic>{},
      );
      pushNotificationsEnabled =
          notificationsSettings['pushEnabled'] as bool? ?? true;
      priceAlertsEnabled =
          notificationsSettings['priceAlertsEnabled'] as bool? ?? true;
      weeklySummaryEnabled =
          notificationsSettings['weeklySummaryEnabled'] as bool? ?? true;
      twoFactorEnabled = securitySettings['twoFactorEnabled'] as bool? ?? false;
      biometricEnabled = securitySettings['biometricEnabled'] as bool? ?? true;
      final cartRaw = (m['cart'] as List?) ?? [];
      cart
        ..clear()
        ..addAll(cartRaw
            .map((e) => Map<String, dynamic>.from(e as Map))
            .map((e) {
              final pid = (e['productId'] ?? '') as String;
              final qty = (e['qty'] as num?)?.toInt() ?? 1;
              final p = findById(pid);
              if (p == null) return null;
              return CartItem(product: p, quantity: qty);
            })
            .whereType<CartItem>());
      notifyListeners();
    });

    _notificationsSub = _svc
        .userNotifications(user!.uid)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .listen((snap) {
      notifications
        ..clear()
        ..addAll(snap.docs.map(AppNotification.fromDoc));
      notifyListeners();
    });

    _productAlertsSub = _svc
        .userProductAlerts(user!.uid)
        .snapshots()
        .listen((snap) {
      productAlerts
        ..clear()
        ..addEntries(snap.docs.map((d) {
          final a = ProductAlert.fromDoc(d);
          return MapEntry(a.productId, a);
        }));
      notifyListeners();
    });

    _initialized = true;
    notifyListeners();
  }

  @override
  void dispose() {
    _productsSub?.cancel();
    _bannersSub?.cancel();
    _userSub?.cancel();
    _notificationsSub?.cancel();
    _productAlertsSub?.cancel();
    super.dispose();
  }

  Product? findById(String id) {
    for (final p in products) {
      if (p.id == id) return p;
    }
    return null;
  }

  // --- Catalog mutations --------------------------------------------------

  Future<void> addPrice({
    required String productId,
    required String store,
    required double price,
  }) async {
    final p = findById(productId);
    if (p == null) return;
    final newHist = [
      ...p.priceHistory.map((e) => e.toMap()),
      PriceEntry(
        store: store,
        price: price,
        date: DateTime.now(),
        reportedBy: user?.displayName ?? 'Sen',
      ).toMap(),
    ];
    await _svc.products.doc(productId).update({'priceHistory': newHist});
    await _addPoints(PointsRules.addPrice);
  }

  Future<void> addProduct({
    required String name,
    required String brand,
    required String category,
    required String emoji,
    required String unit,
  }) async {
    await _svc.products.add({
      'name': name,
      'brand': brand,
      'category': category,
      'emoji': emoji,
      'unit': unit,
      'priceHistory': <Map<String, dynamic>>[],
    });
    await _addPoints(PointsRules.addProduct);
  }

  // --- Favorites ----------------------------------------------------------

  bool isFavorite(String productId) => favorites.contains(productId);

  Future<void> toggleFavorite(String productId) async {
    if (user == null) return;
    final ref = _svc.userDoc(user!.uid);
    if (favorites.contains(productId)) {
      await ref.update({
        'favorites': FieldValue.arrayRemove([productId]),
      });
    } else {
      await ref.update({
        'favorites': FieldValue.arrayUnion([productId]),
      });
      await _addPoints(PointsRules.favorite);
    }
  }

  // --- Cart ---------------------------------------------------------------

  Future<void> addToCart(Product p) async {
    final existing = cart.where((c) => c.product.id == p.id).toList();
    if (existing.isNotEmpty) {
      existing.first.quantity++;
    } else {
      cart.add(CartItem(product: p));
    }
    await _persistCart();
  }

  Future<void> removeFromCart(String productId) async {
    cart.removeWhere((c) => c.product.id == productId);
    await _persistCart();
  }

  Future<void> changeQty(String productId, int delta) async {
    for (final c in cart) {
      if (c.product.id == productId) {
        c.quantity += delta;
        if (c.quantity <= 0) cart.remove(c);
        break;
      }
    }
    await _persistCart();
  }

  Future<void> clearCart() async {
    cart.clear();
    pointsToRedeem = 0;
    await _persistCart();
  }

  Future<void> _persistCart() async {
    if (user == null) return;
    notifyListeners();
    await _svc.userDoc(user!.uid).update({
      'cart': cart
          .map((c) => {'productId': c.product.id, 'qty': c.quantity})
          .toList(),
    });
  }

  void _reconcileCartProducts() {
    // Replace cart items' product references with fresh copies from [products]
    for (var i = 0; i < cart.length; i++) {
      final fresh = findById(cart[i].product.id);
      if (fresh != null) cart[i] = CartItem(product: fresh, quantity: cart[i].quantity);
    }
  }

  // --- Pricing ------------------------------------------------------------

  double get cartSubtotal {
    double total = 0;
    for (final c in cart) {
      total += (c.product.lowestPrice ?? 0) * c.quantity;
    }
    return total;
  }

  /// Savings compared to each item's highest ever price.
  double get cartSavings {
    double s = 0;
    for (final c in cart) {
      if (c.product.priceHistory.isEmpty) continue;
      final high = c.product.priceHistory
          .map((e) => e.price)
          .reduce((a, b) => a > b ? a : b);
      final low = c.product.lowestPrice ?? high;
      s += (high - low) * c.quantity;
    }
    return s;
  }

  double get deliveryFee => cartSubtotal >= 250 || cart.isEmpty ? 0 : 14.9;

  double get redeemDiscount => pointsToRedeem * PointsRules.pointValueTl;

  double get cartTotal {
    final t = cartSubtotal + deliveryFee - redeemDiscount;
    return t < 0 ? 0 : t;
  }

  int get pointsEarnedForCart => (cartSubtotal ~/ 10); // 1 puan per ₺10

  int get cartItemCount => cart.fold(0, (a, c) => a + c.quantity);

  void setRedeemPoints(int p) {
    pointsToRedeem = p.clamp(0, points);
    notifyListeners();
  }

  /// "Checkout": awards earned points, deducts redeemed points, clears cart.
  Future<void> checkout() async {
    if (user == null || cart.isEmpty) return;
    final earn = pointsEarnedForCart;
    final redeem = pointsToRedeem;
    final newPoints = (points - redeem + earn).clamp(0, 1 << 30);
    await _svc.userDoc(user!.uid).update({
      'points': newPoints,
      'cart': <Map<String, dynamic>>[],
      'lastCheckoutAt': FieldValue.serverTimestamp(),
    });
    cart.clear();
    pointsToRedeem = 0;
    notifyListeners();
  }

  // --- Points helpers -----------------------------------------------------

  Future<void> _addPoints(int amount) async {
    if (user == null) return;
    await _svc.userDoc(user!.uid).update({
      'points': FieldValue.increment(amount),
    });
  }

  Future<void> markNotificationRead(String notificationId) async {
    if (user == null) return;
    AppNotification? current;
    for (final n in notifications) {
      if (n.id == notificationId) {
        current = n;
        break;
      }
    }
    if (current == null || current.isRead) return;
    await _svc.userNotifications(user!.uid).doc(notificationId).update({
      'readAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> markAllNotificationsRead() async {
    if (user == null) return;
    final unread = notifications.where((n) => !n.isRead).toList();
    if (unread.isEmpty) return;
    final batch = _svc.db.batch();
    for (final n in unread) {
      batch.update(_svc.userNotifications(user!.uid).doc(n.id), {
        'readAt': FieldValue.serverTimestamp(),
      });
    }
    await batch.commit();
  }

  ProductAlert? alertForProduct(String productId) => productAlerts[productId];

  Future<void> setProductAlert({
    required String productId,
    required double targetPrice,
  }) async {
    if (user == null) return;
    final existing = productAlerts[productId];
    await _svc.userProductAlerts(user!.uid).doc(productId).set({
      'targetPrice': targetPrice,
      'updatedAt': FieldValue.serverTimestamp(),
      'createdAt': existing == null
          ? FieldValue.serverTimestamp()
          : Timestamp.fromDate(existing.createdAt),
    }, SetOptions(merge: true));
  }

  Future<void> updateProfileSettings({
    required String displayName,
    required String username,
    String? phoneNumber,
  }) async {
    if (user == null) return;
    await _svc.userDoc(user!.uid).update({
      'displayName': displayName.trim(),
      'username': username.trim(),
      'phoneNumber': phoneNumber?.trim().isEmpty == true
          ? FieldValue.delete()
          : phoneNumber?.trim(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> updateNotificationSettings({
    bool? pushEnabled,
    bool? priceAlertsEnabled,
    bool? weeklySummaryEnabled,
  }) async {
    if (user == null) return;
    await _svc.userDoc(user!.uid).set({
      'settings': {
        'notifications': {
          if (pushEnabled != null) 'pushEnabled': pushEnabled,
          if (priceAlertsEnabled != null)
            'priceAlertsEnabled': priceAlertsEnabled,
          if (weeklySummaryEnabled != null)
            'weeklySummaryEnabled': weeklySummaryEnabled,
        },
      },
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> updateSecuritySettings({
    bool? twoFactorEnabled,
    bool? biometricEnabled,
  }) async {
    if (user == null) return;
    await _svc.userDoc(user!.uid).set({
      'settings': {
        'security': {
          if (twoFactorEnabled != null) 'twoFactorEnabled': twoFactorEnabled,
          if (biometricEnabled != null) 'biometricEnabled': biometricEnabled,
        },
      },
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> logout() async {
    await _productsSub?.cancel();
    await _bannersSub?.cancel();
    await _userSub?.cancel();
    await _notificationsSub?.cancel();
    await _productAlertsSub?.cancel();
    _productsSub = null;
    _bannersSub = null;
    _userSub = null;
    _notificationsSub = null;
    _productAlertsSub = null;
    products.clear();
    banners.clear();
    favorites.clear();
    notifications.clear();
    productAlerts.clear();
    cart.clear();
    points = 0;
    pointsToRedeem = 0;
    _initialized = false;
    notifyListeners();
    await _svc.auth.signOut();
    await init();
  }

  Future<void> refreshFromAuthSession() async {
    await _productsSub?.cancel();
    await _bannersSub?.cancel();
    await _userSub?.cancel();
    await _notificationsSub?.cancel();
    await _productAlertsSub?.cancel();
    _productsSub = null;
    _bannersSub = null;
    _userSub = null;
    _notificationsSub = null;
    _productAlertsSub = null;
    products.clear();
    banners.clear();
    favorites.clear();
    notifications.clear();
    productAlerts.clear();
    cart.clear();
    points = 0;
    pointsToRedeem = 0;
    _initialized = false;
    notifyListeners();
    await init();
  }
}

class AppStateScope extends InheritedNotifier<AppState> {
  const AppStateScope({
    super.key,
    required AppState state,
    required super.child,
  }) : super(notifier: state);

  static AppState of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<AppStateScope>();
    assert(scope != null, 'AppStateScope not found in widget tree');
    return scope!.notifier!;
  }
}
