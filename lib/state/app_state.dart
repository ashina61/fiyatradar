import 'dart:async';
import 'dart:math' as math;

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
  static const int verifyVote = 1;
  static const int dailyLogin = 5;

  /// 100 puan = ₺5 indirim
  static const double pointValueTl = 0.05;
}

/// Thresholds that drive the community verification state machine.
class VerificationRules {
  /// A user below this trust (0..1) gets weight 0.3 on their vote.
  static const double lowTrustThreshold = 0.2;
  /// A user above this trust (0..1) gets weight up to 1.5 on their vote.
  static const double highTrustThreshold = 0.7;
  /// Minimum total votes before a status may flip out of "pending".
  static const int minVotesForStatus = 3;
  /// Trust-weighted score needed to become "community_verified".
  static const double verifyScore = 1.2;
  /// Trust-weighted score at/below which an entry is "rejected".
  static const double rejectScore = -1.2;
  /// If |score| < this with at least [minVotesForStatus] votes, it's disputed.
  static const double disputeBand = 0.4;
}

/// Vote on a single price entry. Returns the updated verification summary
/// that was committed to Firestore.
enum VoteKind { up, down }

/// Result of a community verification vote.
class VoteResult {
  final PriceStatus newStatus;
  final int upvotes;
  final int downvotes;
  final double trustWeightedScore;
  const VoteResult({
    required this.newStatus,
    required this.upvotes,
    required this.downvotes,
    required this.trustWeightedScore,
  });
}

class AppState extends ChangeNotifier {
  AppState();

  final FirebaseService _svc = FirebaseService.instance;
  static const int _bannerVersionSeed = 1000003;
  static const int _notificationVersionSeed = 1000003;
  static const int _alertVersionSeed = 1000003;
  static const int _requestVersionSeed = 1000003;

  // Auth
  User? user;

  /// Set after the user explicitly picks "continue as guest" on the login
  /// screen. The auth gate treats an anonymous user with this flag off as
  /// logged-out so the login screen is still shown on cold start.
  bool guestAcknowledged = false;

  void setGuestAcknowledged(bool v) {
    if (guestAcknowledged == v) return;
    guestAcknowledged = v;
    notifyListeners();
  }

  /// True when the current user is a fully registered (non-anonymous) user
  /// whose uid matches an admin record or whose profile has the admin flag.
  bool _isAdmin = false;
  bool get isAdmin => _isAdmin;
  bool _isBanned = false;
  bool get isBanned => _isBanned;
  String? banReason;

  // Catalog
  final List<Product> products = [];
  final List<AppBanner> banners = [];
  List<Product> _homeTopDrops = const [];
  List<Product> _homeFeed = const [];
  final Map<String, PriceEntry?> _latestPriceEntryByProduct = {};
  List<(Product, PriceEntry)> _adminRecentEntries = const [];
  List<(Product, PriceEntry)> _adminPendingEntries = const [];
  List<(Product, PriceEntry)> _adminDisputedEntries = const [];
  List<(Product, PriceEntry)> _adminRejectedEntries = const [];
  int _productsVersion = 0;
  int _favoritesVersion = 0;
  List<Product> get homeTopDrops => _homeTopDrops;
  List<Product> get homeFeed => _homeFeed;
  PriceEntry? latestEntryForProduct(String productId) =>
      _latestPriceEntryByProduct[productId];
  List<(Product, PriceEntry)> get adminRecentEntries => _adminRecentEntries;
  List<(Product, PriceEntry)> get adminPendingEntries => _adminPendingEntries;
  List<(Product, PriceEntry)> get adminDisputedEntries => _adminDisputedEntries;
  List<(Product, PriceEntry)> get adminRejectedEntries => _adminRejectedEntries;
  int get productsVersion => _productsVersion;
  int get favoritesVersion => _favoritesVersion;

  // User data (from Firestore user doc)
  Set<String> favorites = <String>{};
  int points = 0;
  int pointsToRedeem = 0; // local, user-chosen redemption
  final List<CartItem> cart = [];
  String displayName = 'Kahve Avcısı';
  String username = '@fiyatradar_user';
  String? phoneNumber;
  String? cityName;
  String? districtName;
  String? profileImageUrl;
  String? profileImagePath;

  bool pushNotificationsEnabled = true;
  bool priceAlertsEnabled = true;
  bool weeklySummaryEnabled = true;
  bool twoFactorEnabled = false;
  bool biometricEnabled = false;
  String? twoFactorPin;
  bool securitySessionUnlocked = false;

  // Trust bookkeeping (0..1 used to weight this user's votes)
  int trustVerifiedTotal = 0;
  int trustWrongTotal = 0;
  int trustTotalVotes = 0;
  int contributions = 0;

  double get trustScore {
    if (trustTotalVotes == 0) return 0.5;
    final good = trustVerifiedTotal.toDouble();
    return (good / trustTotalVotes).clamp(0.0, 1.0);
  }

  int get trustScorePercent => (trustScore * 100).round();

  /// Weight applied to this user's verification vote (0.3 .. 1.5).
  double get voteWeight {
    final t = trustScore;
    if (t <= VerificationRules.lowTrustThreshold) return 0.3;
    if (t >= VerificationRules.highTrustThreshold) {
      final over = (t - VerificationRules.highTrustThreshold) /
          (1 - VerificationRules.highTrustThreshold);
      return 1.0 + 0.5 * over.clamp(0, 1);
    }
    // Linear ramp 0.3 → 1.0 between low and high thresholds.
    const span =
        VerificationRules.highTrustThreshold - VerificationRules.lowTrustThreshold;
    final ratio = (t - VerificationRules.lowTrustThreshold) / span;
    return 0.3 + 0.7 * ratio;
  }

  /// Categories streamed from Firestore. Empty until the first snapshot
  /// arrives — the home tab handles the loading state.
  List<String> categories = const <String>[];

  /// Stores streamed from Firestore. Same fallback strategy as categories.
  List<String> stores = const [];

  /// Pending product requests (admin side).
  List<ProductRequest> productRequests = <ProductRequest>[];

  StreamSubscription? _productsSub;
  StreamSubscription<User?>? _authSub;
  StreamSubscription? _bannersSub;
  StreamSubscription? _storesSub;
  StreamSubscription? _categoriesSub;
  StreamSubscription? _userSub;
  StreamSubscription? _notificationsSub;
  StreamSubscription? _productAlertsSub;
  StreamSubscription? _productRequestsSub;
  bool _initialized = false;
  int _productsSignature = 0;
  bool get initialized => _initialized;
  final List<AppNotification> notifications = [];
  final Map<String, ProductAlert> productAlerts = {};
  int get unreadNotificationCount =>
      notifications.where((n) => !n.isRead).length;

  /// Aggregate new price entries reported in the last 24h, across all
  /// products. Used by the Home hero instead of mock values.
  int get freshContributionCountLast24h {
    final cutoff = DateTime.now().subtract(const Duration(hours: 24));
    var count = 0;
    for (final p in products) {
      for (final e in p.priceHistory) {
        if (e.date.isAfter(cutoff)) count++;
      }
    }
    return count;
  }

  int get aggregateVerifiedCount {
    var n = 0;
    for (final p in products) {
      n += p.verifiedCount;
    }
    return n;
  }

  /// Average trust percentage across products that have any valid entries.
  int get catalogTrustPercent {
    final buckets = products
        .map((p) => p.aggregateTrustPercent)
        .where((p) => p > 0)
        .toList();
    if (buckets.isEmpty) return 0;
    final sum = buckets.reduce((a, b) => a + b);
    return (sum / buckets.length).round();
  }

  /// Stores ranked by how often they appear in catalog price history.
  /// Used by the add-price screen to surface "most frequently added" markets
  /// as quick-pick chips. Falls back to the alphabetical [stores] order when
  /// no price history exists yet.
  List<String> topStoresByFrequency({int limit = 5}) {
    if (limit <= 0) return const <String>[];
    final counts = <String, int>{};
    for (final p in products) {
      for (final e in p.priceHistory) {
        final name = e.store.trim();
        if (name.isEmpty) continue;
        counts[name] = (counts[name] ?? 0) + 1;
      }
    }
    if (counts.isEmpty) {
      return stores.take(limit).toList();
    }
    final ranked = counts.entries.toList()
      ..sort((a, b) {
        final byCount = b.value.compareTo(a.value);
        if (byCount != 0) return byCount;
        return a.key.toLowerCase().compareTo(b.key.toLowerCase());
      });
    return ranked.take(limit).map((e) => e.key).toList();
  }

  /// Week-over-week max price drop percentage across products.
  double get weeklyDropPct {
    double maxDrop = 0;
    for (final p in products) {
      final pct = p.priceChangePct;
      if (pct != null && pct < maxDrop) maxDrop = pct;
    }
    return maxDrop;
  }

  Future<void> init() async {
    _authSub ??= _svc.auth.authStateChanges().listen((next) {
      if (user?.uid == next?.uid &&
          user?.isAnonymous == next?.isAnonymous) {
        return;
      }
      user = next;
      notifyListeners();
    });
    user = await _svc.ensureSignedIn();
    await _svc.bootstrap();

    _productsSub = _svc.products.snapshots().listen((snap) {
      final nextProducts =
          snap.docs.map(Product.fromDoc).where((p) => p.isActive).toList();
      final nextSignature = nextProducts.fold<int>(
        _bannerVersionSeed,
        (acc, p) => Object.hash(acc, _productSignature(p)),
      );
      if (nextSignature == _productsSignature) return;
      _productsSignature = nextSignature;
      products
        ..clear()
        ..addAll(nextProducts);
      _reconcileCartProducts();
      _rebuildCatalogDerivedViews();
      _productsVersion++;
      notifyListeners();
    });

    _bannersSub = _svc.banners
        .where('isActive', isEqualTo: true)
        .snapshots()
        .listen((snap) {
      final next = snap.docs.map(AppBanner.fromDoc).toList()
        ..sort((a, b) => a.order.compareTo(b.order));
      final nextSignature = next.fold<int>(
        _bannerVersionSeed,
        (acc, b) => Object.hash(acc, b.id, b.title, b.subtitle, b.actionLabel, b.order),
      );
      final prevSignature = banners.fold<int>(
        _bannerVersionSeed,
        (acc, b) => Object.hash(acc, b.id, b.title, b.subtitle, b.actionLabel, b.order),
      );
      if (nextSignature == prevSignature) return;
      banners
        ..clear()
        ..addAll(next);
      notifyListeners();
    });

    _storesSub = _svc.stores.snapshots().listen((snap) {
      final docs = snap.docs
          .map((d) => d.data())
          .where((m) => m['isActive'] != false)
          .toList();
      docs.sort((a, b) {
        final ao = (a['order'] as num?)?.toInt() ?? 999;
        final bo = (b['order'] as num?)?.toInt() ?? 999;
        return ao.compareTo(bo);
      });
      final seen = <String>{};
      final names = docs
          .map((m) => (m['name'] ?? '').toString().trim())
          .where((s) => s.isNotEmpty)
          .where((s) => seen.add(s.toLowerCase()))
          .toList();
      final same = names.length == stores.length &&
          names.asMap().entries.every((e) => stores[e.key] == e.value);
      if (!same) {
        stores = names;
        notifyListeners();
      }
    });

    _categoriesSub = _svc.categories.snapshots().listen((snap) {
      final docs = snap.docs
          .map((d) => d.data())
          .where((m) => m['isActive'] != false)
          .toList();
      docs.sort((a, b) {
        final ao = (a['order'] as num?)?.toInt() ?? 999;
        final bo = (b['order'] as num?)?.toInt() ?? 999;
        return ao.compareTo(bo);
      });
      final names = docs
          .map((m) => (m['name'] ?? '').toString())
          .where((s) => s.isNotEmpty)
          .toList();
      final same = names.length == categories.length &&
          names.asMap().entries.every((e) => categories[e.key] == e.value);
      if (!same) {
        categories = names;
        notifyListeners();
      }
    });

    _productRequestsSub = _svc.productRequests
        .orderBy('createdAt', descending: true)
        .snapshots()
        .listen((snap) {
      final next = snap.docs.map(ProductRequest.fromDoc).toList();
      final nextSignature = next.fold<int>(
        _requestVersionSeed,
        (acc, r) => Object.hash(
          acc,
          r.id,
          r.name,
          r.brand,
          r.category,
          r.status,
          r.createdAt.millisecondsSinceEpoch,
          r.requestedByUid,
        ),
      );
      final prevSignature = productRequests.fold<int>(
        _requestVersionSeed,
        (acc, r) => Object.hash(
          acc,
          r.id,
          r.name,
          r.brand,
          r.category,
          r.status,
          r.createdAt.millisecondsSinceEpoch,
          r.requestedByUid,
        ),
      );
      if (nextSignature == prevSignature) return;
      productRequests = next;
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
        'trustVerifiedTotal': 0,
        'trustWrongTotal': 0,
        'trustTotalVotes': 0,
        'contributions': 0,
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
      final prevDisplayName = displayName;
      final prevUsername = username;
      final prevPhone = phoneNumber;
      final prevCity = cityName;
      final prevDistrict = districtName;
      final prevProfileImageUrl = profileImageUrl;
      final prevProfileImagePath = profileImagePath;
      final prevPoints = points;
      final prevTrustVerified = trustVerifiedTotal;
      final prevTrustWrong = trustWrongTotal;
      final prevTrustVotes = trustTotalVotes;
      final prevContributions = contributions;
      final prevFavorites = Set<String>.from(favorites);
      final prevPush = pushNotificationsEnabled;
      final prevPriceAlerts = priceAlertsEnabled;
      final prevWeekly = weeklySummaryEnabled;
      final prevTwoFactor = twoFactorEnabled;
      final prevBiometric = biometricEnabled;
      final prevTwoFactorPin = twoFactorPin;
      final prevIsAdmin = _isAdmin;
      final prevIsBanned = _isBanned;
      final prevBanReason = banReason;
      final prevCartSignature = cart
          .map((c) => '${c.product.id}:${c.quantity}')
          .join('|');

      displayName = (m['displayName'] as String?)?.trim().isNotEmpty == true
          ? (m['displayName'] as String)
          : 'Kahve Avcısı';
      username = (m['username'] as String?)?.trim().isNotEmpty == true
          ? (m['username'] as String)
          : '@fiyatradar_user';
      phoneNumber = (m['phoneNumber'] as String?)?.trim().isNotEmpty == true
          ? (m['phoneNumber'] as String)
          : null;
      final cityRaw = ((m['cityName'] ?? m['city']) as String?)?.trim();
      cityName = (cityRaw?.isNotEmpty ?? false) ? cityRaw : null;
      final districtRaw = ((m['district'] ?? m['neighborhood']) as String?)?.trim();
      districtName = (districtRaw?.isNotEmpty ?? false) ? districtRaw : null;
      profileImageUrl = (m['profileImageUrl'] as String?)?.trim().isNotEmpty == true
          ? (m['profileImageUrl'] as String)
          : null;
      profileImagePath =
          (m['profileImagePath'] as String?)?.trim().isNotEmpty == true
              ? (m['profileImagePath'] as String)
              : null;
      points = (m['points'] as num?)?.toInt() ?? 0;
      trustVerifiedTotal = (m['trustVerifiedTotal'] as num?)?.toInt() ?? 0;
      trustWrongTotal = (m['trustWrongTotal'] as num?)?.toInt() ?? 0;
      trustTotalVotes = (m['trustTotalVotes'] as num?)?.toInt() ?? 0;
      contributions = (m['contributions'] as num?)?.toInt() ?? 0;
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
      biometricEnabled = securitySettings['biometricEnabled'] as bool? ?? false;
      twoFactorPin = (securitySettings['twoFactorPin'] as String?)?.trim().isNotEmpty == true
          ? (securitySettings['twoFactorPin'] as String)
          : null;
      _isAdmin = (m['isAdmin'] as bool?) == true ||
          (m['role'] as String?) == 'admin';
      _isBanned = (m['isBanned'] as bool?) == true;
      banReason = (m['banReason'] as String?)?.trim().isNotEmpty == true
          ? (m['banReason'] as String)
          : null;
      final cartRaw = (m['cart'] as List?) ?? [];
      final nextCart = cartRaw
          .map((e) => Map<String, dynamic>.from(e as Map))
          .map((e) {
            final pid = (e['productId'] ?? '') as String;
            final qty = (e['qty'] as num?)?.toInt() ?? 1;
            final p = findById(pid);
            if (p == null) return null;
            return CartItem(product: p, quantity: qty);
          })
          .whereType<CartItem>()
          .toList();
      cart
        ..clear()
        ..addAll(nextCart);
      final nextCartSignature = cart
          .map((c) => '${c.product.id}:${c.quantity}')
          .join('|');
      final favoritesChanged =
          prevFavorites.length != favorites.length ||
              !prevFavorites.containsAll(favorites);
      if (favoritesChanged) {
        _favoritesVersion++;
      }
      final changed = prevDisplayName != displayName ||
          prevUsername != username ||
          prevPhone != phoneNumber ||
          prevCity != cityName ||
          prevDistrict != districtName ||
          prevProfileImageUrl != profileImageUrl ||
          prevProfileImagePath != profileImagePath ||
          prevPoints != points ||
          prevTrustVerified != trustVerifiedTotal ||
          prevTrustWrong != trustWrongTotal ||
          prevTrustVotes != trustTotalVotes ||
          prevContributions != contributions ||
          favoritesChanged ||
          prevPush != pushNotificationsEnabled ||
          prevPriceAlerts != priceAlertsEnabled ||
          prevWeekly != weeklySummaryEnabled ||
          prevTwoFactor != twoFactorEnabled ||
          prevBiometric != biometricEnabled ||
          prevTwoFactorPin != twoFactorPin ||
          prevIsAdmin != _isAdmin ||
          prevIsBanned != _isBanned ||
          prevBanReason != banReason ||
          prevCartSignature != nextCartSignature;
      if (changed) notifyListeners();
    });

    _notificationsSub = _svc
        .userNotifications(user!.uid)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .listen((snap) {
      final next = snap.docs.map(AppNotification.fromDoc).toList();
      final nextSignature = next.fold<int>(
        _notificationVersionSeed,
        (acc, n) => Object.hash(
          acc,
          n.id,
          n.title,
          n.body,
          n.createdAt.millisecondsSinceEpoch,
          n.readAt?.millisecondsSinceEpoch,
        ),
      );
      final prevSignature = notifications.fold<int>(
        _notificationVersionSeed,
        (acc, n) => Object.hash(
          acc,
          n.id,
          n.title,
          n.body,
          n.createdAt.millisecondsSinceEpoch,
          n.readAt?.millisecondsSinceEpoch,
        ),
      );
      if (nextSignature == prevSignature) return;
      notifications
        ..clear()
        ..addAll(next);
      notifyListeners();
    });

    _productAlertsSub = _svc
        .userProductAlerts(user!.uid)
        .snapshots()
        .listen((snap) {
      final nextEntries = snap.docs.map((d) {
        final a = ProductAlert.fromDoc(d);
        return MapEntry(a.productId, a);
      });
      final next = Map<String, ProductAlert>.fromEntries(nextEntries);
      final nextSignature = next.values.fold<int>(
        _alertVersionSeed,
        (acc, a) => Object.hash(
          acc,
          a.productId,
          a.targetPrice,
          a.createdAt.millisecondsSinceEpoch,
        ),
      );
      final prevSignature = productAlerts.values.fold<int>(
        _alertVersionSeed,
        (acc, a) => Object.hash(
          acc,
          a.productId,
          a.targetPrice,
          a.createdAt.millisecondsSinceEpoch,
        ),
      );
      if (nextSignature == prevSignature) return;
      productAlerts
        ..clear()
        ..addAll(next);
      notifyListeners();
    });

    _initialized = true;
    notifyListeners();
  }

  @override
  void dispose() {
    _productsSub?.cancel();
    _authSub?.cancel();
    _bannersSub?.cancel();
    _storesSub?.cancel();
    _categoriesSub?.cancel();
    _userSub?.cancel();
    _notificationsSub?.cancel();
    _productAlertsSub?.cancel();
    _productRequestsSub?.cancel();
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
    String note = '',
    String? proofImageUrl,
  }) async {
    final p = findById(productId);
    if (p == null) return;
    final uid = user?.uid ?? '';
    final entryId = '${productId}_${DateTime.now().millisecondsSinceEpoch}_${_rand4()}';
    final entry = PriceEntry(
      id: entryId,
      store: store,
      price: price,
      date: DateTime.now(),
      reportedBy: user?.displayName?.trim().isNotEmpty == true
          ? user!.displayName!
          : displayName,
      reportedByUid: uid,
      note: note,
      proofImageUrl: proofImageUrl,
      status: PriceStatus.pending,
      statusUpdatedAt: DateTime.now(),
    );
    final newHist = [
      ...p.priceHistory.map((e) => e.toMap()),
      entry.toMap(),
    ];
    await _svc.products.doc(productId).update({'priceHistory': newHist});
    await _addPoints(PointsRules.addPrice);
    if (uid.isNotEmpty) {
      await _svc.userDoc(uid).set({
        'contributions': FieldValue.increment(1),
      }, SetOptions(merge: true));
    }
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

  // --- Admin: product management -----------------------------------------

  Future<String> adminCreateProduct({
    required String name,
    required String brand,
    required String category,
    required String emoji,
    required String unit,
    String? imageUrl,
    String? imagePath,
    String? barcode,
    bool isActive = true,
  }) async {
    final doc = await _svc.products.add({
      'name': name.trim(),
      'brand': brand.trim(),
      'category': category,
      'emoji': emoji,
      'unit': unit.trim(),
      if (imageUrl != null) 'imageUrl': imageUrl,
      if (imagePath != null) 'imagePath': imagePath,
      if (barcode != null && barcode.isNotEmpty) 'barcode': barcode,
      'isActive': isActive,
      'priceHistory': <Map<String, dynamic>>[],
      'createdAt': FieldValue.serverTimestamp(),
      'createdByUid': user?.uid ?? '',
    });
    return doc.id;
  }

  Future<void> adminUpdateProduct({
    required String productId,
    String? name,
    String? brand,
    String? category,
    String? emoji,
    String? unit,
    String? imageUrl,
    String? imagePath,
    String? barcode,
    bool? isActive,
  }) async {
    await _svc.products.doc(productId).update({
      if (name != null) 'name': name.trim(),
      if (brand != null) 'brand': brand.trim(),
      if (category != null) 'category': category,
      if (emoji != null) 'emoji': emoji,
      if (unit != null) 'unit': unit.trim(),
      if (imageUrl != null) 'imageUrl': imageUrl,
      if (imagePath != null) 'imagePath': imagePath,
      if (barcode != null) 'barcode': barcode,
      if (isActive != null) 'isActive': isActive,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> adminDeleteProduct(String productId) async {
    await _svc.products.doc(productId).delete();
  }

  Future<void> adminApproveRequest({
    required ProductRequest req,
    String? emojiOverride,
    String? unitOverride,
    String? imageUrl,
    String? imagePath,
  }) async {
    final productId = await adminCreateProduct(
      name: req.name,
      brand: req.brand,
      category: req.category,
      emoji: emojiOverride ?? req.emoji,
      unit: unitOverride ?? req.unit,
      imageUrl: imageUrl,
      imagePath: imagePath,
      barcode: req.barcode,
    );
    await _svc.productRequests.doc(req.id).update({
      'status': 'approved',
      'approvedProductId': productId,
      'decidedAt': FieldValue.serverTimestamp(),
      'decidedByUid': user?.uid ?? '',
    });
    if (req.requestedByUid.isNotEmpty) {
      await _svc
          .userNotifications(req.requestedByUid)
          .add({
        'title': 'Ürün talebin onaylandı',
        'body': '${req.name} artık katalogta. Fiyat paylaşıp puan kazan.',
        'createdAt': FieldValue.serverTimestamp(),
        'type': 'product_request_approved',
        'productId': productId,
      });
    }
  }

  /// Admin override: force a community price entry into a target status
  /// (e.g. "katalog onaylı" → community_verified). Bypasses voting rules.
  Future<void> adminSetPriceEntryStatus({
    required String productId,
    required String entryId,
    required PriceStatus status,
  }) async {
    final ref = _svc.products.doc(productId);
    await _svc.db.runTransaction((tx) async {
      final snap = await tx.get(ref);
      if (!snap.exists) return;
      final raw = (snap.data()?['priceHistory'] as List?) ?? [];
      final history = raw
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();
      final idx = history.indexWhere((e) => e['id'] == entryId);
      if (idx == -1) return;
      final current = PriceEntry.fromMap(history[idx]);
      final updated = current.copyWith(
        status: status,
        statusUpdatedAt: DateTime.now(),
      );
      history[idx] = updated.toMap();
      tx.update(ref, {
        'priceHistory': history,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    });
  }

  Future<void> adminRejectRequest({
    required ProductRequest req,
    String reason = '',
  }) async {
    await _svc.productRequests.doc(req.id).update({
      'status': 'rejected',
      'rejectionReason': reason,
      'decidedAt': FieldValue.serverTimestamp(),
      'decidedByUid': user?.uid ?? '',
    });
    if (req.requestedByUid.isNotEmpty) {
      await _svc
          .userNotifications(req.requestedByUid)
          .add({
        'title': 'Ürün talebin reddedildi',
        'body': reason.isEmpty
            ? '${req.name} kataloğa uygun değil.'
            : '${req.name}: $reason',
        'createdAt': FieldValue.serverTimestamp(),
        'type': 'product_request_rejected',
      });
    }
  }

  // --- Verification --------------------------------------------------------

  /// Reasons a verification vote can be rejected client-side.
  /// UI should show a user-friendly message for each.
  String? canVoteOn(Product product, PriceEntry entry) {
    final uid = user?.uid;
    if (uid == null || uid.isEmpty) return 'Oy vermek için giriş yap.';
    if (entry.isOwnedBy(uid)) {
      return 'Kendi girdiğin fiyata oy veremezsin.';
    }
    if (entry.voters.containsKey(uid)) {
      return 'Bu fiyata zaten oy verdin.';
    }
    return null;
  }

  /// Casts a community verification vote. Transactional so concurrent votes
  /// don't corrupt the tallies. Also updates the voter's trust totals.
  Future<VoteResult?> voteOnPrice({
    required Product product,
    required PriceEntry entry,
    required VoteKind kind,
  }) async {
    final uid = user?.uid;
    if (uid == null || uid.isEmpty) return null;
    final blocked = canVoteOn(product, entry);
    if (blocked != null) {
      throw StateError(blocked);
    }

    final weight = voteWeight;
    final productRef = _svc.products.doc(product.id);
    final voterRef = _svc.userDoc(uid);

    VoteResult? result;

    await _svc.db.runTransaction((tx) async {
      final snap = await tx.get(productRef);
      if (!snap.exists) return;
      final raw = (snap.data()?['priceHistory'] as List?) ?? [];
      final history = raw
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();
      final idx = history.indexWhere((e) => e['id'] == entry.id);
      if (idx == -1) return;
      final current = PriceEntry.fromMap(history[idx]);
      if (current.isOwnedBy(uid) || current.voters.containsKey(uid)) return;

      final up = kind == VoteKind.up;
      final newUp = current.upvotes + (up ? 1 : 0);
      final newDown = current.downvotes + (up ? 0 : 1);
      final delta = up ? weight : -weight;
      final newScore = current.trustWeightedScore + delta;

      PriceStatus next = current.status;
      final totalVotes = newUp + newDown;
      if (totalVotes >= VerificationRules.minVotesForStatus) {
        if (newScore >= VerificationRules.verifyScore) {
          next = PriceStatus.communityVerified;
        } else if (newScore <= VerificationRules.rejectScore) {
          next = PriceStatus.rejected;
        } else if (newScore.abs() < VerificationRules.disputeBand) {
          next = PriceStatus.disputed;
        } else {
          next = PriceStatus.pending;
        }
      }

      final updated = current.copyWith(
        upvotes: newUp,
        downvotes: newDown,
        verifiedByCount: newUp,
        rejectedByCount: newDown,
        trustWeightedScore: newScore,
        status: next,
        statusUpdatedAt: DateTime.now(),
        voters: {
          ...current.voters,
          uid: up ? 'up' : 'down',
        },
      );
      history[idx] = updated.toMap();
      tx.update(productRef, {'priceHistory': history});

      // Reward the voter's trust bucket. Whether this vote is "correct" is
      // decided by the entry's final status after this vote: community
      // alignment boosts trust, disagreement dings it.
      final alignedWithStatus = (next == PriceStatus.communityVerified && up) ||
          (next == PriceStatus.rejected && !up);
      final alignedSoft = (next == PriceStatus.pending) &&
          ((newScore > 0 && up) || (newScore < 0 && !up));
      final good = alignedWithStatus || alignedSoft;
      tx.set(
        voterRef,
        {
          'trustTotalVotes': FieldValue.increment(1),
          if (good) 'trustVerifiedTotal': FieldValue.increment(1),
          if (!good) 'trustWrongTotal': FieldValue.increment(1),
          'points': FieldValue.increment(PointsRules.verifyVote),
        },
        SetOptions(merge: true),
      );

      result = VoteResult(
        newStatus: next,
        upvotes: newUp,
        downvotes: newDown,
        trustWeightedScore: newScore,
      );
    });

    return result;
  }

  String _rand4() {
    final r = math.Random();
    const chars = 'abcdefghijklmnopqrstuvwxyz0123456789';
    return List.generate(4, (_) => chars[r.nextInt(chars.length)]).join();
  }

  // --- Favorites ----------------------------------------------------------

  bool isFavorite(String productId) => favorites.contains(productId);

  Future<void> toggleFavorite(String productId) async {
    if (user == null) return;
    final ref = _svc.userDoc(user!.uid);
    final hadFavorite = favorites.contains(productId);
    if (hadFavorite) {
      favorites.remove(productId);
    } else {
      favorites.add(productId);
    }
    _favoritesVersion++;
    notifyListeners();
    try {
      if (hadFavorite) {
        await ref.update({
          'favorites': FieldValue.arrayRemove([productId]),
        });
      } else {
        await ref.update({
          'favorites': FieldValue.arrayUnion([productId]),
        });
        await _addPoints(PointsRules.favorite);
      }
    } catch (_) {
      if (hadFavorite) {
        favorites.add(productId);
      } else {
        favorites.remove(productId);
      }
      _favoritesVersion++;
      notifyListeners();
      rethrow;
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
    for (var i = 0; i < cart.length; i++) {
      final fresh = findById(cart[i].product.id);
      if (fresh != null) cart[i] = CartItem(product: fresh, quantity: cart[i].quantity);
    }
  }

  void _rebuildCatalogDerivedViews() {
    final droppers = [...products]
      ..sort((a, b) {
        final ap = a.priceChangePct ?? 0;
        final bp = b.priceChangePct ?? 0;
        return ap.compareTo(bp);
      });
    _homeTopDrops =
        droppers.where((p) => (p.priceChangePct ?? 0) < 0).take(3).toList();

    final feed = [...products]
      ..sort((a, b) {
        final ad = a.priceHistory.isEmpty ? DateTime(0) : a.priceHistory.last.date;
        final bd = b.priceHistory.isEmpty ? DateTime(0) : b.priceHistory.last.date;
        return bd.compareTo(ad);
      });
    _homeFeed = feed.take(4).toList();

    _latestPriceEntryByProduct
      ..clear()
      ..addEntries(products.map((p) => MapEntry(
            p.id,
            p.priceHistory.isEmpty ? null : p.priceHistory.last,
          )));

    final recent = <(Product, PriceEntry)>[];
    final pending = <(Product, PriceEntry)>[];
    final disputed = <(Product, PriceEntry)>[];
    final rejected = <(Product, PriceEntry)>[];
    for (final p in products) {
      for (final e in p.priceHistory) {
        recent.add((p, e));
        if (e.status == PriceStatus.pending) pending.add((p, e));
        if (e.status == PriceStatus.disputed) disputed.add((p, e));
        if (e.status == PriceStatus.rejected) rejected.add((p, e));
      }
    }
    recent.sort((a, b) => b.$2.date.compareTo(a.$2.date));
    pending.sort((a, b) => b.$2.date.compareTo(a.$2.date));
    disputed.sort((a, b) => b.$2.date.compareTo(a.$2.date));
    rejected.sort((a, b) => b.$2.date.compareTo(a.$2.date));
    _adminRecentEntries = recent;
    _adminPendingEntries = pending;
    _adminDisputedEntries = disputed;
    _adminRejectedEntries = rejected;
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
    String? profileImageUrl,
    String? profileImagePath,
  }) async {
    if (user == null) {
      throw StateError('Aktif kullanıcı bulunamadı.');
    }
    await _svc.userDoc(user!.uid).update({
      'displayName': displayName.trim(),
      'username': username.trim(),
      'phoneNumber': phoneNumber?.trim().isEmpty == true
          ? FieldValue.delete()
          : phoneNumber?.trim(),
      if (profileImageUrl != null) 'profileImageUrl': profileImageUrl,
      if (profileImagePath != null) 'profileImagePath': profileImagePath,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> updateRegionSettings({
    required String cityName,
    String? districtName,
  }) async {
    if (user == null) {
      throw StateError('Aktif kullanıcı bulunamadı.');
    }
    await _svc.userDoc(user!.uid).set({
      'cityName': cityName.trim(),
      if (districtName != null && districtName.trim().isNotEmpty)
        'district': districtName.trim()
      else
        'district': FieldValue.delete(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> reportPriceEntry({
    required Product product,
    required PriceEntry entry,
    required String reason,
  }) async {
    final uid = user?.uid;
    if (uid == null || uid.isEmpty) return;
    final ref = _svc.db.collection('priceReports').doc('${uid}_${entry.id}');
    await _svc.db.runTransaction((tx) async {
      final snap = await tx.get(ref);
      if (snap.exists) {
        final status = (snap.data()?['status'] as String?) ?? 'active';
        if (status == 'active') {
          throw StateError('Bu fiyatı zaten raporladın.');
        }
        throw StateError(
            'Bu fiyat için önceki raporun sonuçlandı. Tekrar raporlayamazsın.');
      }
      tx.set(ref, {
        'productId': product.id,
        'entryId': entry.id,
        'createdByUid': uid,
        'price': entry.price,
        'storeName': entry.store,
        if (reason.trim().isNotEmpty) 'reason': reason.trim(),
        'status': 'active',
        'verificationStatus': 'unverified',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    });
  }

  /// Admin moderation for a price report. Marks the report status and
  /// optionally removes the reported price entry from the product history.
  Future<void> adminResolvePriceReport({
    required String reportId,
    required String productId,
    required String entryId,
    required bool removeEntry,
  }) async {
    final reportRef = _svc.db.collection('priceReports').doc(reportId);
    final productRef = _svc.products.doc(productId);
    await _svc.db.runTransaction((tx) async {
      final reportSnap = await tx.get(reportRef);
      if (!reportSnap.exists) return;

      if (removeEntry) {
        final productSnap = await tx.get(productRef);
        if (productSnap.exists) {
          final raw = (productSnap.data()?['priceHistory'] as List?) ?? [];
          final history = raw
              .map((e) => Map<String, dynamic>.from(e as Map))
              .where((e) => e['id'] != entryId)
              .toList();
          tx.update(productRef, {
            'priceHistory': history,
            'updatedAt': FieldValue.serverTimestamp(),
          });
        }
      }

      tx.update(reportRef, {
        'status': removeEntry ? 'removed' : 'reviewed',
        'resolvedByUid': user?.uid ?? '',
        'resolvedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
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
    String? twoFactorPin,
    bool clearTwoFactorPin = false,
  }) async {
    if (user == null) return;
    await _svc.userDoc(user!.uid).set({
      'settings': {
        'security': {
          if (twoFactorEnabled != null) 'twoFactorEnabled': twoFactorEnabled,
          if (biometricEnabled != null) 'biometricEnabled': biometricEnabled,
          if (twoFactorPin != null) 'twoFactorPin': twoFactorPin.trim(),
          if (clearTwoFactorPin) 'twoFactorPin': FieldValue.delete(),
        },
      },
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  void markSecuritySessionUnlocked(bool value) {
    if (securitySessionUnlocked == value) return;
    securitySessionUnlocked = value;
    notifyListeners();
  }

  Future<void> logout() async {
    await _productsSub?.cancel();
    await _authSub?.cancel();
    await _bannersSub?.cancel();
    await _storesSub?.cancel();
    await _categoriesSub?.cancel();
    await _userSub?.cancel();
    await _notificationsSub?.cancel();
    await _productAlertsSub?.cancel();
    await _productRequestsSub?.cancel();
    _productsSub = null;
    _authSub = null;
    _bannersSub = null;
    _storesSub = null;
    _categoriesSub = null;
    _userSub = null;
    _notificationsSub = null;
    _productAlertsSub = null;
    _productRequestsSub = null;
    products.clear();
    banners.clear();
    favorites.clear();
    notifications.clear();
    productAlerts.clear();
    cart.clear();
    points = 0;
    pointsToRedeem = 0;
    phoneNumber = null;
    cityName = null;
    districtName = null;
    profileImageUrl = null;
    profileImagePath = null;
    trustVerifiedTotal = 0;
    trustWrongTotal = 0;
    trustTotalVotes = 0;
    contributions = 0;
    twoFactorPin = null;
    securitySessionUnlocked = false;
    guestAcknowledged = false;
    _isAdmin = false;
    _isBanned = false;
    banReason = null;
    _initialized = false;
    _productsSignature = 0;
    notifyListeners();
    await _svc.auth.signOut();
    await init();
  }

  Future<void> refreshFromAuthSession({
    bool preserveGuestAcknowledged = true,
  }) async {
    final wasGuestAcknowledged = guestAcknowledged;
    await _productsSub?.cancel();
    await _authSub?.cancel();
    await _bannersSub?.cancel();
    await _storesSub?.cancel();
    await _categoriesSub?.cancel();
    await _userSub?.cancel();
    await _notificationsSub?.cancel();
    await _productAlertsSub?.cancel();
    await _productRequestsSub?.cancel();
    _productsSub = null;
    _authSub = null;
    _bannersSub = null;
    _storesSub = null;
    _categoriesSub = null;
    _userSub = null;
    _notificationsSub = null;
    _productAlertsSub = null;
    _productRequestsSub = null;
    products.clear();
    banners.clear();
    favorites.clear();
    notifications.clear();
    productAlerts.clear();
    cart.clear();
    points = 0;
    pointsToRedeem = 0;
    phoneNumber = null;
    cityName = null;
    districtName = null;
    profileImageUrl = null;
    profileImagePath = null;
    trustVerifiedTotal = 0;
    trustWrongTotal = 0;
    trustTotalVotes = 0;
    contributions = 0;
    twoFactorPin = null;
    securitySessionUnlocked = false;
    guestAcknowledged = preserveGuestAcknowledged
        ? wasGuestAcknowledged
        : false;
    _isAdmin = false;
    _isBanned = false;
    banReason = null;
    _initialized = false;
    _productsSignature = 0;
    notifyListeners();
    await init();
  }

  /// Syncs [user] from FirebaseAuth immediately so auth-gated navigation
  /// can react without waiting for full data re-initialization.
  void syncUserFromAuthSession() {
    final next = _svc.auth.currentUser;
    if (next == null) return;
    if (user?.uid == next.uid && user?.isAnonymous == next.isAnonymous) return;
    user = next;
    notifyListeners();
  }

  int _productSignature(Product p) {
    var entriesSig = _bannerVersionSeed;
    for (final e in p.priceHistory) {
      entriesSig = Object.hash(entriesSig, _priceEntrySignature(e));
    }
    return Object.hash(
      p.id,
      p.name,
      p.brand,
      p.category,
      p.emoji,
      p.unit,
      p.imageUrl,
      p.imagePath,
      p.barcode,
      p.isActive,
      entriesSig,
    );
  }

  int _priceEntrySignature(PriceEntry e) {
    final sortedVoters = e.voters.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));
    final votersSig = Object.hashAll(
      sortedVoters.map((v) => Object.hash(v.key, v.value)),
    );
    return Object.hash(
      e.id,
      e.store,
      e.price,
      e.date.millisecondsSinceEpoch,
      e.reportedBy,
      e.reportedByUid,
      e.note,
      e.proofImageUrl,
      e.upvotes,
      e.downvotes,
      e.verifiedByCount,
      e.rejectedByCount,
      e.trustWeightedScore,
      e.status.name,
      e.statusUpdatedAt?.millisecondsSinceEpoch,
      votersSig,
    );
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
