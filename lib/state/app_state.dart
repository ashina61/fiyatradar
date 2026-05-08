import 'dart:async';
import 'dart:math' as math;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/widgets.dart';

import '../models/comment.dart';
import '../models/gamification.dart';
import '../models/price_v1.dart';
import '../models/price_reporting.dart';
import '../models/product.dart';
import '../models/turkey_locations.dart';
import '../services/basket_pricing_service.dart';
import '../services/firebase_service.dart';
import '../services/messaging_service.dart';
import '../services/premium_service.dart';
import '../services/price_report_service.dart';

// NOT: AppState god-class refactor (extension/part'lara bölme) Aşama 3+
// backlog'unda kaldı. Test pasta olmadan private state alanlarını
// disturb etmek riskli; önce widget testleri yazılmalı, sonra
// `app_state.gamification.dart`, `app_state.admin.dart`,
// `app_state.regional.dart` part dosyalarına dağıtım yapılabilir.
// Bu commit'te yalnız feature delivery + minor temizlik.

/// Points awarded for different actions in the rewards system.
///
/// IMPORTANT: Tek bir aksiyonun puan ödülü 50'yi aşmamalı. Firestore rules
/// (`hasSafeUserGamificationMutation`) tek update'te `points` artışını +50
/// ile sınırlıyor; daha yüksek bir ödül vermek istersen önce rule'u güncelle.
class PointsRules {
  static const int addPrice = 10;
  static const int addProduct = 25;
  static const int photoBonus = 5; // Fotoğraflı fiyat ekstra ödülü
  static const int favorite = 2;
  static const int verifyVote = 1;

  /// Daily login bonus — şu an çağrılmıyor (streak/login akışı henüz yok).
  /// Streak özelliği eklendiğinde Cloud Function tarafından dağıtılmalı,
  /// client tek başına self-credit verilemeyecek şekilde tasarlanmalı.
  static const int dailyLogin = 5;

  /// 100 puan = ₺5 indirim (gelecekteki Premium / kupon akışı için tutuluyor).
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
enum HomePriceScope { nearby, city, online, turkeyWide }

/// Internal: contribution kind for the gamification reward pipeline.
enum _ContribKind { report, verify }

/// `priceHistory` legacy mirror'ını kontrol eden feature flag.
///
/// Audit raporundaki Aşama 3 maddesi: "priceHistory array tamamen
/// kaldırma + Cloud Function geçişi". Flag'i `false` yapıp release
/// alındığında:
///   1. AppState.addRegionalPrice artık priceEntries doc + array push
///      yapmıyor; yeni omurga (priceReports + priceGroups) tek otorite.
///   2. functions/index.js onProductPriceDrop tetiklenmez (priceHistory
///      değişmez); bunun yerine `onPriceGroupUpdate` push'lar.
///   3. Profil "Katkılarım" zaten priceReports'tan okuyor → etkilenmez.
///   4. Product detail _DetailHeadlinePrice legacy lowestPrice fallback'i
///      kullanmaya devam eder (mevcut katalog için tarihsel veri).
///
/// İlk release `true` (geri uyum); büyük şehirlerde bir sonraki sürümde
/// `false`'a çekilecek.
const bool kEnableLegacyPriceHistoryMirror = true;

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
  late final PriceReportService _priceReportService = PriceReportService(_svc);
  final BasketPricingService _basketPricingService = const BasketPricingService();
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
  final Map<String, PriceEntry?> _homeScopedEntryByProduct = {};
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
  PriceEntry? homeScopedEntryForProduct(String productId) =>
      _homeScopedEntryByProduct[productId];
  bool get homeUsesScopedEntries => _homeScopedEntryByProduct.isNotEmpty;
  Set<String> get homeScopedProductIds => _homeScopedEntryByProduct.keys.toSet();
  List<PriceEntry> get homeScopedEntries =>
      _homeScopedEntryByProduct.values.whereType<PriceEntry>().toList();
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
  HomePriceScope activeHomeScope = HomePriceScope.nearby;

  bool pushNotificationsEnabled = true;
  bool priceAlertsEnabled = true;
  bool weeklySummaryEnabled = true;
  /// `regional_price_drop` push'larına abonelik. Cloud Function
  /// `onPriceGroupUpdate` notification doc'unu yine yazar (in-app sinyali
  /// kaybolmaması için), ama push gönderirken bu bayrağı kontrol etmesi
  /// gerekiyor (TODO: functions/index.js bu alanı henüz okumuyor — bir
  /// sonraki Cloud Functions deploy'unda eklenmeli).
  bool regionalDropPushEnabled = true;
  bool twoFactorEnabled = false;
  bool biometricEnabled = false;
  String? twoFactorPin;
  bool securitySessionUnlocked = false;

  // Trust bookkeeping (0..1 used to weight this user's votes)
  int trustVerifiedTotal = 0;
  int trustWrongTotal = 0;
  int trustTotalVotes = 0;
  int contributions = 0;

  // Gamification: streak + verifyContributions + photoContributions
  int verifyContributions = 0;
  int photoContributions = 0;
  int currentStreak = 0;
  int longestStreak = 0;
  DateTime? lastContributionDay;
  Set<String> badges = <String>{};

  // FiyatRadar Pro durumu — Cloud Function (purchaseQueue → Play
  // Developer API doğrulama) yazar; istemci yalnız okur. UI tarafı
  // `state.premium.isActive` getter'ı üzerinden gating yapar.
  bool _isPremium = false;
  DateTime? _premiumUntil;
  String? _premiumPlan;
  PremiumStatus get premium => PremiumStatus(
        isActive: _isPremium &&
            (_premiumUntil == null ||
                _premiumUntil!.isAfter(DateTime.now())),
        until: _premiumUntil,
        plan: _premiumPlan,
      );

  /// Birleşik gamification snapshot — UI'nın kullanması için tek nokta.
  GamificationSnapshot get gamification => GamificationSnapshot(
        points: points,
        contributions: contributions,
        verifyContributions: verifyContributions,
        photoContributions: photoContributions,
        currentStreak: currentStreak,
        longestStreak: longestStreak,
        lastContributionDay: lastContributionDay,
        badges: Set<String>.from(badges),
      );

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

  /// Optional one-shot preset for the Explore tab consumed by banner taps.
  /// `_explorePresetFilter` matches the index in `ExploreTab._filters`.
  int? _explorePresetFilter;
  String? _explorePresetCategory;
  int? consumeExplorePresetFilter() {
    final v = _explorePresetFilter;
    _explorePresetFilter = null;
    return v;
  }

  String? consumeExplorePresetCategory() {
    final v = _explorePresetCategory;
    _explorePresetCategory = null;
    return v;
  }

  void setExplorePresetFilter(int index) {
    _explorePresetFilter = index;
  }

  void setExplorePresetCategory(String name) {
    final trimmed = name.trim();
    _explorePresetCategory = trimmed.isEmpty ? null : trimmed;
  }


  // Add-price preset queue. The basket "fill missing for chain X" flow can
  // queue multiple products; the add-price tab consumes them one by one so
  // the user can add several missing prices in a row without re-navigating
  // each time.
  final List<String> _addPricePresetProductIds = <String>[];
  String? _addPricePresetChainId;
  String? _addPricePresetChainName;

  ({String? productId, String? chainId, String? chainName, int remaining})
      consumeAddPricePreset() {
    final pid = _addPricePresetProductIds.isEmpty
        ? null
        : _addPricePresetProductIds.removeAt(0);
    final out = (
      productId: pid,
      chainId: _addPricePresetChainId,
      chainName: _addPricePresetChainName,
      remaining: _addPricePresetProductIds.length,
    );
    if (_addPricePresetProductIds.isEmpty) {
      // Last item drained → also drop the chain context so a future
      // unrelated tap doesn't carry it forward.
      _addPricePresetChainId = null;
      _addPricePresetChainName = null;
    }
    return out;
  }

  /// Returns the number of products still queued for add-price preset
  /// consumption (0 when nothing is queued).
  int get addPricePresetQueueLength => _addPricePresetProductIds.length;

  void setAddPricePreset({
    String? productId,
    String? chainId,
    String? chainName,
  }) {
    _addPricePresetProductIds
      ..clear()
      ..addAll(productId == null ? const <String>[] : <String>[productId]);
    _addPricePresetChainId = chainId;
    _addPricePresetChainName = chainName;
  }

  /// Queue multiple products to be added in succession (used by the basket
  /// "fill missing for chain X" CTA). `chainId` / `chainName` apply to the
  /// whole batch so the user only picks the market once.
  void queueAddPricePreset({
    required List<String> productIds,
    String? chainId,
    String? chainName,
  }) {
    _addPricePresetProductIds
      ..clear()
      ..addAll(productIds.where((e) => e.trim().isNotEmpty));
    _addPricePresetChainId = chainId;
    _addPricePresetChainName = chainName;
  }

  StreamSubscription? _productsSub;
  StreamSubscription<User?>? _authSub;
  StreamSubscription? _bannersSub;
  StreamSubscription? _storesSub;
  StreamSubscription? _categoriesSub;
  StreamSubscription? _userSub;
  StreamSubscription? _notificationsSub;
  StreamSubscription? _productAlertsSub;
  StreamSubscription? _productRequestsSub;
  StreamSubscription? _regionalPriceEntriesSub;
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
      int sig(AppBanner b) => Object.hash(
            b.id,
            b.title,
            b.subtitle,
            b.actionLabel,
            b.order,
            b.imageUrl,
            b.actionType,
            b.actionTarget,
            b.contentBlocks.length,
          );
      final nextSignature = next.fold<int>(
        _bannerVersionSeed,
        (acc, b) => Object.hash(acc, sig(b)),
      );
      final prevSignature = banners.fold<int>(
        _bannerVersionSeed,
        (acc, b) => Object.hash(acc, sig(b)),
      );
      if (nextSignature == prevSignature) return;
      banners
        ..clear()
        ..addAll(next);
      notifyListeners();
    });

    _storesSub = _svc.stores.limit(200).snapshots().listen((snap) {
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
      final prevRegionalDrop = regionalDropPushEnabled;
      final prevTwoFactor = twoFactorEnabled;
      final prevBiometric = biometricEnabled;
      final prevTwoFactorPin = twoFactorPin;
      final prevIsAdmin = _isAdmin;
      final prevIsBanned = _isBanned;
      final prevBanReason = banReason;
      final prevHomeScope = activeHomeScope;
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
      verifyContributions =
          (m['verifyContributions'] as num?)?.toInt() ?? 0;
      photoContributions =
          (m['photoContributions'] as num?)?.toInt() ?? 0;
      currentStreak = (m['currentStreak'] as num?)?.toInt() ?? 0;
      longestStreak = (m['longestStreak'] as num?)?.toInt() ?? 0;
      final streakTs = m['lastContributionDay'];
      lastContributionDay = streakTs is Timestamp
          ? streakTs.toDate()
          : (streakTs is String ? DateTime.tryParse(streakTs) : null);
      badges = ((m['badges'] as List?) ?? const [])
          .map((e) => e.toString())
          .toSet();
      _isPremium = (m['isPremium'] as bool?) == true;
      final premiumUntilTs = m['premiumUntil'];
      _premiumUntil = premiumUntilTs is Timestamp
          ? premiumUntilTs.toDate()
          : (premiumUntilTs is String
              ? DateTime.tryParse(premiumUntilTs)
              : null);
      _premiumPlan = (m['premiumPlan'] as String?)?.trim().isNotEmpty == true
          ? (m['premiumPlan'] as String)
          : null;
      final homeScopeRaw = (m['homeScope'] as String?)?.trim();
      activeHomeScope = switch (homeScopeRaw) {
        'city' => HomePriceScope.city,
        'online' => HomePriceScope.online,
        'turkey_wide' => HomePriceScope.turkeyWide,
        _ => HomePriceScope.nearby,
      };
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
      regionalDropPushEnabled =
          notificationsSettings['regionalDropPushEnabled'] as bool? ?? true;
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
          prevRegionalDrop != regionalDropPushEnabled ||
          prevTwoFactor != twoFactorEnabled ||
          prevBiometric != biometricEnabled ||
          prevTwoFactorPin != twoFactorPin ||
          prevIsAdmin != _isAdmin ||
          prevIsBanned != _isBanned ||
          prevBanReason != banReason ||
          prevHomeScope != activeHomeScope ||
          prevCartSignature != nextCartSignature;
      if (prevCity != cityName ||
          prevDistrict != districtName ||
          prevHomeScope != activeHomeScope) {
        _bindRegionalPriceFeed();
      }
      if (changed) notifyListeners();
    });

    _bindRegionalPriceFeed();

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

  static const List<String> _visiblePriceStatuses = <String>[
    'pending',
    'community_verified',
    'disputed',
  ];

  String get homeScopeLabel {
    return switch (activeHomeScope) {
      HomePriceScope.nearby => 'Yakınımda',
      HomePriceScope.city => 'Şehrimde',
      HomePriceScope.online => 'Online',
      HomePriceScope.turkeyWide => 'Türkiye geneli',
    };
  }

  String get homeScopeTitle {
    switch (activeHomeScope) {
      case HomePriceScope.nearby:
        final city = (cityName ?? '').trim();
        final district = (districtName ?? '').trim();
        if (city.isEmpty || district.isEmpty) return 'Bölgesel akış';
        return 'Bölgesel akış · $city / $district';
      case HomePriceScope.city:
        final city = (cityName ?? '').trim();
        return city.isEmpty ? 'Şehir akışı' : 'Şehir akışı · $city';
      case HomePriceScope.online:
        return 'Online fiyatlar';
      case HomePriceScope.turkeyWide:
        return 'Türkiye geneli fiyatlar';
    }
  }

  String get homeScopeSubtitle {
    return switch (activeHomeScope) {
      HomePriceScope.nearby => 'Yakınındaki market ve pazar katkıları',
      HomePriceScope.city => 'Şehrinden gelen market ve pazar katkıları',
      HomePriceScope.online => 'Online marketlerden son fiyat paylaşımları',
      HomePriceScope.turkeyWide => 'Diğer bölgelerden topluluk fiyatları',
    };
  }

  String get homeScopeEmptyMessage {
    switch (activeHomeScope) {
      case HomePriceScope.nearby:
        if ((cityName ?? '').trim().isEmpty || (districtName ?? '').trim().isEmpty) {
          return 'Bölgeni seç, yakın fiyatları gösterelim.';
        }
        return 'Bu bölgede henüz fiyat paylaşımı yok.';
      case HomePriceScope.city:
        if ((cityName ?? '').trim().isEmpty) {
          return 'Şehir akışı için önce bölgeni seç.';
        }
        return 'Bu şehirde henüz fiyat paylaşımı yok.';
      case HomePriceScope.online:
        return 'Henüz online fiyat paylaşımı yok.';
      case HomePriceScope.turkeyWide:
        return 'Türkiye geneli için henüz paylaşım yok.';
    }
  }

  Query<Map<String, dynamic>> _baseScopedPriceQuery({required int limit}) {
    return _svc.priceEntries
        .where('status', whereIn: _visiblePriceStatuses)
        .orderBy('createdAt', descending: true)
        .limit(limit);
  }

  PriceEntry _priceEntryFromDoc(
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final m = doc.data();
    final ts = m['createdAt'];
    return PriceEntry(
      id: doc.id,
      store: (m['placeDisplayName'] ?? '').toString(),
      price: (m['price'] as num?)?.toDouble() ?? 0,
      date: ts is Timestamp ? ts.toDate() : DateTime.now(),
      reportedBy: (m['reportedByName'] ?? 'Topluluk').toString(),
      reportedByUid: (m['reportedByUid'] ?? '').toString(),
      note: (m['note'] ?? '').toString(),
      city: (m['city'] as String?)?.trim().isNotEmpty == true
          ? (m['city'] as String)
          : null,
      district: (m['district'] as String?)?.trim().isNotEmpty == true
          ? (m['district'] as String)
          : null,
      status: switch ((m['status'] ?? 'pending').toString()) {
        'community_verified' => PriceStatus.communityVerified,
        'disputed' => PriceStatus.disputed,
        'rejected' => PriceStatus.rejected,
        _ => PriceStatus.pending,
      },
    );
  }

  Stream<List<PriceEntry>> watchProductLocalEntries({
    required String productId,
    required String city,
    required String district,
    int limit = 20,
  }) {
    return _svc.priceEntries
        .where('productId', isEqualTo: productId)
        .where('scope', whereIn: const ['local', 'bazaar'])
        .where('city', isEqualTo: city)
        .where('district', isEqualTo: district)
        .where('status', whereIn: _visiblePriceStatuses)
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((snap) => snap.docs.map(_priceEntryFromDoc).toList());
  }

  Stream<List<PriceEntry>> watchProductCityEntries({
    required String productId,
    required String city,
    int limit = 20,
  }) {
    return _svc.priceEntries
        .where('productId', isEqualTo: productId)
        .where('scope', whereIn: const ['local', 'bazaar'])
        .where('city', isEqualTo: city)
        .where('status', whereIn: _visiblePriceStatuses)
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((snap) => snap.docs.map(_priceEntryFromDoc).toList());
  }

  Stream<List<PriceEntry>> watchProductOnlineEntries({
    required String productId,
    int limit = 20,
  }) {
    return _svc.priceEntries
        .where('productId', isEqualTo: productId)
        .where('scope', isEqualTo: 'online')
        .where('status', whereIn: _visiblePriceStatuses)
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((snap) => snap.docs.map(_priceEntryFromDoc).toList());
  }

  Stream<List<PriceEntry>> watchProductTurkeyEntries({
    required String productId,
    int limit = 30,
  }) {
    return _svc.priceEntries
        .where('productId', isEqualTo: productId)
        .where('scope', whereIn: const ['local', 'bazaar'])
        .where('status', whereIn: _visiblePriceStatuses)
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((snap) => snap.docs.map(_priceEntryFromDoc).toList());
  }


  void _bindRegionalPriceFeed() {
    _regionalPriceEntriesSub?.cancel();
    final city = (cityName ?? '').trim();
    final district = (districtName ?? '').trim();
    Query<Map<String, dynamic>> q = _baseScopedPriceQuery(limit: 120);
    switch (activeHomeScope) {
      case HomePriceScope.nearby:
        if (city.isEmpty || district.isEmpty) {
          _homeScopedEntryByProduct.clear();
          notifyListeners();
          return;
        }
        q = q
            .where('scope', whereIn: const ['local', 'bazaar'])
            .where('city', isEqualTo: city)
            .where('district', isEqualTo: district);
        break;
      case HomePriceScope.city:
        if (city.isEmpty) {
          _homeScopedEntryByProduct.clear();
          notifyListeners();
          return;
        }
        q = q
            .where('scope', whereIn: const ['local', 'bazaar'])
            .where('city', isEqualTo: city);
        break;
      case HomePriceScope.online:
        q = q.where('scope', isEqualTo: 'online');
        break;
      case HomePriceScope.turkeyWide:
        q = q.where('scope', whereIn: const ['local', 'bazaar']);
        break;
    }
    _regionalPriceEntriesSub = q.snapshots().listen((snap) {
      final next = <String, PriceEntry?>{};
      for (final d in snap.docs) {
        final m = d.data();
        final pid = (m['productId'] ?? '').toString();
        if (pid.isEmpty || next.containsKey(pid)) continue;
        next[pid] = _priceEntryFromDoc(d);
      }
      _homeScopedEntryByProduct
        ..clear()
        ..addAll(next);
      notifyListeners();
    });
  }

  Future<void> setHomePriceScope(HomePriceScope scope) async {
    if (activeHomeScope == scope) return;
    activeHomeScope = scope;
    _bindRegionalPriceFeed();
    notifyListeners();
    final uid = user?.uid;
    if (uid != null && uid.isNotEmpty) {
      await _svc.userDoc(uid).set({
        'homeScope': switch (scope) {
          HomePriceScope.nearby => 'nearby',
          HomePriceScope.city => 'city',
          HomePriceScope.online => 'online',
          HomePriceScope.turkeyWide => 'turkey_wide',
        },
      }, SetOptions(merge: true));
    }
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
    _regionalPriceEntriesSub?.cancel();
    super.dispose();
  }

  Product? findById(String id) {
    for (final p in products) {
      if (p.id == id) return p;
    }
    return null;
  }

  // --- Catalog mutations --------------------------------------------------


  Future<AddPriceSubmitResult> addRegionalPrice({
    required String productId,
    required String store,
    required double price,
    required String chainId,
    required String chainName,
    required String city,
    required String district,
    String note = '',
    String? proofImageUrl,
    String? barcode,
    // placeId opsiyonel — spec "şube zorunlu değil" diyor. Yoksa rapor
    // sourceType=manualRegional olarak kayıt edilir; chain + city + district
    // bağlantısı zaten yeterli.
    String? placeId,
    PriceSourceType sourceType = PriceSourceType.physical,
    double? lat,
    double? lng,
    double? distanceToBranchMeters,
    double? gpsAccuracyMeters,
  }) async {
    final p = findById(productId);
    if (p == null) throw StateError('Ürün bulunamadı.');
    final uid = user?.uid ?? '';
    if (uid.isEmpty) throw StateError('Fiyat eklemek için giriş yapmalısın.');
    final isOnlineSource = sourceType == PriceSourceType.online;
    // Online entries are nationwide — they bypass the Türkiye city/district
    // whitelist and use the canonical "Türkiye / Online" pair so the same
    // schema still works.
    final String cityTrim;
    final String districtTrim;
    if (isOnlineSource) {
      cityTrim = 'Türkiye';
      districtTrim = 'Online';
    } else {
      final canonicalCity = TurkeyLocations.canonicalCity(city);
      if (canonicalCity == null) {
        throw StateError('Geçersiz il: "$city". Listeden seç.');
      }
      final canonicalDistrict =
          TurkeyLocations.canonicalDistrict(canonicalCity, district);
      if (canonicalDistrict == null) {
        throw StateError(
            'Geçersiz ilçe: "$district". $canonicalCity ilçelerinden seç.');
      }
      cityTrim = canonicalCity;
      districtTrim = canonicalDistrict;
    }
    final resolvedChainId = chainId.trim().isEmpty ? store : chainId;
    final resolvedChainName = chainName.trim().isEmpty ? store : chainName;
    final resolvedReporterName = user?.displayName?.trim().isNotEmpty == true
        ? user!.displayName!
        : displayName;
    final resolvedPlaceId = (placeId ?? '').trim();
    final now = DateTime.now();
    final entryId = '${productId}_${now.millisecondsSinceEpoch}_${_rand4()}';
    final legacyEntry = PriceEntry(
      id: entryId,
      store: store,
      price: price,
      date: now,
      reportedBy: resolvedReporterName,
      reportedByUid: uid,
      note: note,
      proofImageUrl: proofImageUrl,
      city: cityTrim,
      district: districtTrim,
      status: PriceStatus.pending,
      statusUpdatedAt: now,
    );
    final legacyEntryPayload = <String, dynamic>{
      'productId': productId,
      'productNameSnapshot': p.name,
      'productBrandSnapshot': p.brand,
      'price': price,
      'scope': scopeForSourceType(sourceType),
      'sourceType': priceSourceTypeToString(sourceType),
      'chainId': resolvedChainId,
      'chainName': resolvedChainName,
      'placeId': resolvedPlaceId.isEmpty ? null : resolvedPlaceId,
      'placeDisplayName': store,
      'city': cityTrim,
      'district': districtTrim,
      'lat': lat,
      'lng': lng,
      'createdAt': FieldValue.serverTimestamp(),
      'expiresAt': Timestamp.fromDate(now.add(const Duration(days: 14))),
      'reportedByUid': uid,
      'reportedByName': resolvedReporterName,
      'status': 'pending',
      'upvotes': 0,
      'downvotes': 0,
      'voters': <String, String>{},
      'trustWeightedScore': 0.0,
      'note': note,
      'proofImageUrl': proofImageUrl,
      'legacy': {
        'compatProductPriceHistory': true,
      }
    };
    final productRef = _svc.products.doc(productId);
    final legacyEntryRef = _svc.priceEntries.doc(entryId);

    final result = await _priceReportService.submitRegionalPrice(
      productId: productId,
      productName: p.name,
      chainId: resolvedChainId,
      chainName: resolvedChainName,
      cityName: cityTrim,
      districtName: districtTrim,
      price: price,
      userId: uid,
      userDisplayName: resolvedReporterName,
      branchId: resolvedPlaceId.isEmpty ? null : resolvedPlaceId,
      branchName: store,
      distanceToBranchMeters: distanceToBranchMeters,
      gpsAccuracyMeters: gpsAccuracyMeters,
      location: (lat != null && lng != null) ? GeoPoint(lat, lng) : null,
      note: note.trim().isEmpty ? null : note.trim(),
      photoUrl: proofImageUrl,
      barcode: barcode,
      // Legacy mirror writes — `kEnableLegacyPriceHistoryMirror` flag'i
      // `false` olduğunda atlanır. Yeni omurga (priceReports +
      // priceGroups) zaten tüm UX yollarına bağlı; mirror sadece eski
      // ProductDetail headline ve `onProductPriceDrop` Cloud Function
      // için var. Aşama 3 phase-out: bu callback kaldırıldığında
      // products.priceHistory artık büyümez ve 1MB doc-limit baskısı
      // yok olur.
      prepareLegacyMirror: kEnableLegacyPriceHistoryMirror
          ? (tx) async {
              // Read fazı: priceHistory'yi şimdi okuyup snapshot'ını alıyoruz.
              final productSnap = await tx.get(productRef);
              if (!productSnap.exists) {
                throw StateError('Ürün bulunamadı.');
              }
              final rawHistory =
                  (productSnap.data()?['priceHistory'] as List?) ?? const [];
              final newHist = [
                ...rawHistory.map((e) => Map<String, dynamic>.from(e as Map)),
                legacyEntry.toMap(),
              ];
              // Write fazı: ana yazmalardan sonra çalıştırılacak closure.
              return (tx, _) {
                tx.set(legacyEntryRef, legacyEntryPayload);
                tx.update(productRef, {'priceHistory': newHist});
              };
            }
          : null,
    );

    if (result.createdReport) {
      // Optimistic local insert into the home community feed cache so that
      // the price the user just submitted appears immediately on the home
      // tab — the Firestore snapshot listener will reconcile within a
      // tick and replace this entry with the canonical doc id.
      _injectOptimisticHomeFeedEntry(
        productId: productId,
        sourceType: sourceType,
        store: store,
        price: price,
        city: cityTrim,
        district: districtTrim,
        reporterName: resolvedReporterName,
        reporterUid: uid,
        note: note,
      );
      // Streak ileri al + rozet ekle + temel +10 PT.
      // Fotoğraflı bildirim için ekstra +5 PT (PointsRules.photoBonus).
      // İlk fiyat / 10. fiyat / 50. fiyat eşiklerinde rozet ödülü.
      await _awardContributionRewards(
        uid: uid,
        kind: _ContribKind.report,
        hasPhoto: (proofImageUrl ?? '').isNotEmpty,
      );
    }
    return result;
  }

  void _injectOptimisticHomeFeedEntry({
    required String productId,
    required PriceSourceType sourceType,
    required String store,
    required double price,
    required String city,
    required String district,
    required String reporterName,
    required String reporterUid,
    required String note,
  }) {
    final entryScope = scopeForSourceType(sourceType);
    final scopeMatches = switch (activeHomeScope) {
      HomePriceScope.nearby =>
        entryScope != 'online' && city == (cityName ?? '').trim() &&
            district == (districtName ?? '').trim(),
      HomePriceScope.city =>
        entryScope != 'online' && city == (cityName ?? '').trim(),
      HomePriceScope.online => entryScope == 'online',
      HomePriceScope.turkeyWide => entryScope != 'online',
    };
    if (!scopeMatches) return;
    final optimistic = PriceEntry(
      id: '_optimistic_${DateTime.now().millisecondsSinceEpoch}',
      store: store,
      price: price,
      date: DateTime.now(),
      reportedBy: reporterName,
      reportedByUid: reporterUid,
      note: note,
      city: city,
      district: district,
      status: PriceStatus.pending,
    );
    final next = <String, PriceEntry?>{
      productId: optimistic,
      ..._homeScopedEntryByProduct,
    };
    _homeScopedEntryByProduct
      ..clear()
      ..addAll(next);
    notifyListeners();
  }

  Future<void> _awardContributionRewards({
    required String uid,
    required _ContribKind kind,
    bool hasPhoto = false,
  }) async {
    // Mevcut snapshot'tan streak ilerlet.
    final adv = StreakCalculator.advance(
      currentStreak: currentStreak,
      longestStreak: longestStreak,
      lastContributionDay: lastContributionDay,
    );
    // Yeni rozet kazançlarını hesapla — sadece daha önce kazanılmamış olanları
    // ekle. Çift sayımı engellemek için badge id-set merge yapıyoruz.
    final earned = <FRBadge>[];
    final nextContribs = kind == _ContribKind.report
        ? contributions + 1
        : contributions;
    final nextVerifies = kind == _ContribKind.verify
        ? verifyContributions + 1
        : verifyContributions;
    final nextPhotos =
        (kind == _ContribKind.report && hasPhoto) ? photoContributions + 1 : photoContributions;

    if (kind == _ContribKind.report) {
      if (nextContribs >= 1 && !badges.contains(FRBadges.firstReport.id)) {
        earned.add(FRBadges.firstReport);
      }
      if (nextContribs >= 10 && !badges.contains(FRBadges.tenReports.id)) {
        earned.add(FRBadges.tenReports);
      }
      if (nextContribs >= 50 && !badges.contains(FRBadges.fiftyReports.id)) {
        earned.add(FRBadges.fiftyReports);
      }
      if (hasPhoto && !badges.contains(FRBadges.firstPhoto.id)) {
        earned.add(FRBadges.firstPhoto);
      }
    } else {
      if (nextVerifies >= 1 && !badges.contains(FRBadges.firstVerify.id)) {
        earned.add(FRBadges.firstVerify);
      }
      if (nextVerifies >= 10 && !badges.contains(FRBadges.tenVerifies.id)) {
        earned.add(FRBadges.tenVerifies);
      }
    }
    if (adv.currentStreak >= 3 && !badges.contains(FRBadges.streak3.id)) {
      earned.add(FRBadges.streak3);
    }
    if (adv.currentStreak >= 7 && !badges.contains(FRBadges.streak7.id)) {
      earned.add(FRBadges.streak7);
    }
    if (adv.currentStreak >= 30 && !badges.contains(FRBadges.streak30.id)) {
      earned.add(FRBadges.streak30);
    }

    // Toplam puan delta'sı: temel ödül + (varsa) fotoğraf bonusu + rozet
    // ödülleri. Firestore rules `points` artışını <= +50 ile sınırlandırıyor;
    // yukarıdaki en agresif kombinasyon (50 raporda streak30 ile çakışırsa
    // 100 PT badge) bu cap'i geçer → bu özel durumda rozet bir sonraki
    // güne ertelenir, çünkü `points` write'ı reddolur. Cap'e sığacak şekilde
    // ödülü bölüyoruz: temel + photoBonus + en yüksek 1 rozet ödülü.
    final base = kind == _ContribKind.report
        ? PointsRules.addPrice
        : PointsRules.verifyVote;
    final photoBonus = (kind == _ContribKind.report && hasPhoto)
        ? PointsRules.photoBonus
        : 0;
    int badgeReward = 0;
    if (earned.isNotEmpty) {
      // En yüksek rozet ödülünü ver, ötekiler için ayrı update.
      earned.sort((a, b) => b.rewardPoints.compareTo(a.rewardPoints));
      badgeReward = earned.first.rewardPoints;
    }
    final pointsDelta = base + photoBonus + badgeReward;
    final cappedDelta = pointsDelta > 50 ? 50 : pointsDelta;

    final updates = <String, dynamic>{
      'points': FieldValue.increment(cappedDelta),
      'currentStreak': adv.currentStreak,
      'longestStreak': adv.longestStreak,
      'lastContributionDay': Timestamp.fromDate(adv.today),
    };
    if (kind == _ContribKind.report) {
      updates['contributions'] = FieldValue.increment(1);
      if (hasPhoto) {
        updates['photoContributions'] = FieldValue.increment(1);
      }
    } else {
      updates['verifyContributions'] = FieldValue.increment(1);
    }
    if (earned.isNotEmpty) {
      updates['badges'] =
          FieldValue.arrayUnion(earned.map((b) => b.id).toList());
    }
    await _svc.userDoc(uid).set(updates, SetOptions(merge: true));

    // Geri kalan rozetleri sırayla, sonraki gün cap'i dolmasın diye
    // her birini ayrı update ile ödüllendiriyoruz — pratikte +1 update
    // yeterli, çünkü tek seferde 2'den fazla rozet açılması nadir.
    if (earned.length > 1) {
      for (final b in earned.skip(1)) {
        await _svc.userDoc(uid).set({
          'points': FieldValue.increment(b.rewardPoints.clamp(0, 50)),
        }, SetOptions(merge: true));
      }
    }
  }

  /// Doğrulama oyu vermek için ön-koşul kontrolü. UI'nın "Ben de gördüm"
  /// butonunu disable etmesi için kullanılır — `null` döndürürse oy
  /// verilebilir; metin döndürürse o sebep kullanıcıya gösterilmeli.
  String? canVerifyRegionalPrice({
    required String city,
    required String district,
  }) {
    final uid = user?.uid ?? '';
    if (uid.isEmpty) return 'Doğrulama için giriş yapmalısın.';
    final activeCity = (cityName ?? '').trim();
    final activeDistrict = (districtName ?? '').trim();
    if (activeCity.isEmpty || activeDistrict.isEmpty) {
      return 'Önce kendi bölgeni seç.';
    }
    if (activeCity.toLowerCase() != city.trim().toLowerCase() ||
        activeDistrict.toLowerCase() != district.trim().toLowerCase()) {
      return 'Sadece kendi bölgen ($activeDistrict / $activeCity) için doğrulayabilirsin.';
    }
    return null;
  }

  Future<void> verifyRegionalPriceSeen({
    required String productId,
    required String chainId,
    required double price,
    required String city,
    required String district,
  }) async {
    final blocked = canVerifyRegionalPrice(city: city, district: district);
    if (blocked != null) throw StateError(blocked);
    final uid = user!.uid;
    await _priceReportService.verifySeenToday(
      productId: productId,
      chainId: chainId,
      cityName: city,
      districtName: district,
      price: price,
      userId: uid,
    );
    // Verify de bir katkı — streak ilerletir, rozet açabilir.
    await _awardContributionRewards(
      uid: uid,
      kind: _ContribKind.verify,
    );
  }

  /// Bölgesel katkıcı sıralaması — `scope` ve `windowDays`'e göre
  /// `priceReports`'tan aggregate çıkarır. UI'nın hem ilçe / şehir /
  /// Türkiye geneli hem de 7 / 30 gün filtresi yapabilmesi için.
  ///
  /// Index gereksinimleri (firestore.indexes.json):
  ///   • district scope:  (cityId, districtId, createdAt DESC)
  ///   • city scope:      (cityId, createdAt DESC)
  ///   • turkey scope:    (createdAt DESC) — built-in
  ///
  /// Pro-only: limit 200 (ücretsiz) → Pro kullanıcılar için 500'e çıkar
  /// (top-100 görüntüleme audit'te Pro feature olarak tanımlandı).
  Stream<List<RegionalContributorScore>> watchRegionalContributorBoard({
    String? city,
    String? district,
    int windowDays = 30,
    int limit = 200,
  }) {
    final cutoff =
        DateTime.now().subtract(Duration(days: windowDays.clamp(1, 90)));
    Query<Map<String, dynamic>> q = _svc.priceReports
        .where('createdAt', isGreaterThan: Timestamp.fromDate(cutoff));
    if (city != null && city.trim().isNotEmpty) {
      q = q.where('cityId', isEqualTo: PriceReportService.normalizeId(city));
    }
    if (district != null && district.trim().isNotEmpty) {
      q = q.where(
        'districtId',
        isEqualTo: PriceReportService.normalizeId(district),
      );
    }
    return q
        .orderBy('createdAt', descending: true)
        .limit(limit.clamp(20, 500))
        .snapshots()
        .map(_aggregateContributors);
  }

  List<RegionalContributorScore> _aggregateContributors(
    QuerySnapshot<Map<String, dynamic>> snap,
  ) {
    final byUser = <String, RegionalContributorScore>{};
    for (final d in snap.docs) {
      final m = d.data();
      final uid = (m['userId'] ?? '').toString();
      if (uid.isEmpty) continue;
      final name = (m['userDisplayName'] ?? '').toString();
      final ts = m['createdAt'];
      final created = ts is Timestamp ? ts.toDate() : null;
      final hasPhoto =
          (m['photoUrl'] as String?)?.trim().isNotEmpty == true;
      final existing = byUser[uid];
      byUser[uid] = RegionalContributorScore(
        userId: uid,
        userDisplayName:
            (existing?.userDisplayName.isNotEmpty ?? false)
                ? existing!.userDisplayName
                : (name.isNotEmpty ? name : 'Topluluk'),
        reportCount: (existing?.reportCount ?? 0) + 1,
        photoCount: (existing?.photoCount ?? 0) + (hasPhoto ? 1 : 0),
        lastReportedAt: () {
          if (existing?.lastReportedAt == null) return created;
          if (created == null) return existing!.lastReportedAt;
          return created.isAfter(existing!.lastReportedAt!)
              ? created
              : existing.lastReportedAt;
        }(),
      );
    }
    final list = byUser.values.toList()
      ..sort((a, b) {
        final byScore = b.score.compareTo(a.score);
        if (byScore != 0) return byScore;
        // Eşitlikte en son rapor eden ileride.
        final ad = a.lastReportedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        final bd = b.lastReportedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        return bd.compareTo(ad);
      });
    return list;
  }

  /// Kullanıcının kendi gönderdiği fiyat raporlarını canlı izler. Profil
  /// "Katkılarım" sekmesi için ana veri kaynağıdır — eskiden legacy
  /// `products.priceHistory` array'i tarıyordu, mirror kalktığında veri
  /// kayboluyordu. Yeni omurga `priceReports` koleksiyonu üzerinden çalışır.
  ///
  /// Not: limit parametresi UI'nın "load more" butonu ile artırabilmesi
  /// için exposed. Default 50 (çoğu kullanıcı için yeterli); ekstra
  /// sayfa için ayrı stream subscribe edilir.
  Stream<List<MyPriceContribution>> watchMyContributions({int limit = 50}) {
    final uid = user?.uid;
    if (uid == null || uid.isEmpty) {
      return const Stream<List<MyPriceContribution>>.empty();
    }
    return _svc.priceReports
        .where('userId', isEqualTo: uid)
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((snap) =>
            snap.docs.map(MyPriceContribution.fromDoc).toList(growable: false));
  }

  /// Admin moderation: yakın zamanda güncellenmiş priceGroups dokümanlarını
  /// listele. Yetkisiz kullanıcı için boş döner (UI tarafı zaten
  /// `state.isAdmin` ile flag'liyor; rule de read'i public bıraktı, write'ı
  /// kısıtlıyor).
  Stream<List<PriceGroupModel>> watchAdminRecentPriceGroups({int limit = 50}) {
    return _svc.priceGroups
        .orderBy('updatedAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((snap) => snap.docs.map(PriceGroupModel.fromDoc).toList());
  }

  /// Admin: bir priceGroup doc'unu `verifiedCount=0`, `confidence=low` ve
  /// `trustedPrice=latestPrice` olarak resetler — kötü niyetli manipülasyonu
  /// yumuşat ya da gerçek raf fiyatı çok değiştiyse start-over olarak.
  /// rules tarafı zaten alan whitelist + sayaç +1 cap koyuyor; admin client
  /// için aynı rule altında bu reset DENIED olur. Bu yüzden updatedAt'a
  /// dokunup admin client'ın yetkisi olduğundan emin olmak için
  /// `isAdmin == true` user doc'undan kontrol ediliyor (rules helper).
  ///
  /// Production hardening: bu reset bir admin Cloud Function'a taşınmalı.
  Future<void> adminResetPriceGroupAggregates({
    required String groupId,
  }) async {
    if (!isAdmin) {
      throw StateError('Yalnız admin kullanıcı bu reseti yapabilir.');
    }
    await _svc.priceGroups.doc(groupId).set({
      'verifiedCount': 0,
      'confidence': 'low',
      'updatedAt': FieldValue.serverTimestamp(),
      // lastReporterId == auth.uid invariant'ını korumak için admin'in
      // kendi uid'sini koyuyoruz; rule yine sıkı tutar.
      'lastReporterId': user?.uid ?? '',
    }, SetOptions(merge: true));
    await _svc.db.collection('adminActions').add({
      'actorUid': user?.uid ?? '',
      'action': 'priceGroup.reset',
      'targetId': groupId,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  /// Admin: tüm "pending" durumdaki store_places dokümanlarını verilen
  /// limite kadar listele. Onay/red işlemi `adminApproveStorePlace` ve
  /// `adminRejectStorePlace` üzerinden.
  Stream<List<Map<String, dynamic>>> watchAdminPendingStorePlaces({
    int limit = 50,
  }) {
    return _svc.storePlaces
        .where('isActive', isEqualTo: true)
        .where('status', isEqualTo: 'pending')
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => {'id': d.id, ...d.data()})
            .toList(growable: false));
  }

  Future<void> adminApproveStorePlace(String placeId) async {
    if (!isAdmin) {
      throw StateError('Yalnız admin onaylayabilir.');
    }
    await _svc.storePlaces.doc(placeId).set({
      'status': 'verified',
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
    await _svc.db.collection('adminActions').add({
      'actorUid': user?.uid ?? '',
      'action': 'storePlace.approve',
      'targetId': placeId,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> adminRejectStorePlace(String placeId) async {
    if (!isAdmin) {
      throw StateError('Yalnız admin reddedebilir.');
    }
    await _svc.storePlaces.doc(placeId).set({
      'isActive': false,
      'status': 'rejected',
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
    await _svc.db.collection('adminActions').add({
      'actorUid': user?.uid ?? '',
      'action': 'storePlace.reject',
      'targetId': placeId,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Stream<List<PriceGroupModel>> watchRegionalPriceGroups({
    required String productId,
    required String city,
    required String district,
    int limit = 20,
  }) {
    final cityId = PriceReportService.normalizeId(city);
    final districtId = PriceReportService.normalizeId(district);
    return _svc.priceGroups
        .where('cityId', isEqualTo: cityId)
        .where('districtId', isEqualTo: districtId)
        .limit(120)
        .snapshots()
        .map((snap) {
      final all = snap.docs
          .map(PriceGroupModel.fromDoc)
          .where((g) => g.productId == productId)
          .toList()
        ..sort((a, b) {
          final ad = a.lastReportedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
          final bd = b.lastReportedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
          return bd.compareTo(ad);
        });
      return all.take(limit).toList();
    });
  }

  Future<List<PriceGroupModel>> fetchRegionalPriceGroupsForProducts({
    required List<String> productIds,
    required String city,
    required String district,
  }) async {
    final cityId = PriceReportService.normalizeId(city);
    final districtId = PriceReportService.normalizeId(district);
    final normalized = productIds.toSet().where((e) => e.trim().isNotEmpty).toList();
    if (normalized.isEmpty) return const <PriceGroupModel>[];

    final snap = await _svc.priceGroups
        .where('cityId', isEqualTo: cityId)
        .where('districtId', isEqualTo: districtId)
        .limit(250)
        .get();
    return snap.docs
        .map(PriceGroupModel.fromDoc)
        .where((g) => normalized.contains(g.productId))
        .toList();
  }

  Future<BasketPricingResult> calculateRegionalBasketPricing() async {
    final city = (cityName ?? '').trim();
    final district = (districtName ?? '').trim();
    if (city.isEmpty || district.isEmpty) {
      return const BasketPricingResult(
        singleMarketEstimates: <BasketStoreEstimate>[],
        cheapestMixed: null,
        smartSuggestion: null,
      );
    }
    final items = cart
        .map((c) => (productId: c.product.id, quantity: c.quantity))
        .toList(growable: false);
    final groups = await fetchRegionalPriceGroupsForProducts(
      productIds: items.map((e) => e.productId).toList(),
      city: city,
      district: district,
    );
    final result = _basketPricingService.calculate(items: items, groups: groups);
    // Cache'i güncelle ki sepet footer'ı (cartSubtotal/cartSavings) yeni
    // omurganın tahmini değerini kullansın — legacy `lowestPrice` fallback
    // yalnız compare panel hiç açılmamışsa devreye girsin.
    updateBasketEstimateCache(result);
    return result;
  }

  // --- Comments -----------------------------------------------------------

  /// Stream comments for a product, newest first. The query is filtered
  /// client-side so a missing composite index doesn't break the listing —
  /// it loads up to 100 docs and sorts in memory. Firestore rules permit
  /// public reads of `comments`.
  Stream<List<ProductComment>> watchProductComments(String productId) {
    return _svc.comments
        .where('productId', isEqualTo: productId)
        .limit(100)
        .snapshots()
        .map((snap) {
      final list = snap.docs.map(ProductComment.fromDoc).toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return list;
    });
  }

  Future<String> addProductComment({
    required String productId,
    required String text,
  }) async {
    final uid = user?.uid ?? '';
    if (uid.isEmpty) throw StateError('Yorum için giriş yapmalısın.');
    final clean = text.trim();
    if (clean.length < 2) throw StateError('Yorum çok kısa.');
    if (clean.length > 1000) throw StateError('Yorum çok uzun.');
    final ref = _svc.comments.doc();
    await ref.set({
      'productId': productId,
      'userId': uid,
      'text': clean,
      'likes': 0,
      'likedBy': <String>[],
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
    return ref.id;
  }

  Future<void> updateProductComment({
    required String commentId,
    required String text,
  }) async {
    final clean = text.trim();
    if (clean.length < 2) throw StateError('Yorum çok kısa.');
    if (clean.length > 1000) throw StateError('Yorum çok uzun.');
    await _svc.comments.doc(commentId).update({
      'text': clean,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> deleteProductComment(String commentId) async {
    await _svc.comments.doc(commentId).delete();
  }

  /// Toggle a like on a comment. Uses an array transaction so concurrent
  /// likes don't drift the `likes` count from `likedBy` length.
  ///
  /// NOTE: Firestore rules forbid non-owner updates to `likes`/`likedBy`
  /// (see `hasOnlyCommentOwnerWritableKeys`). Until the rules expand to
  /// allow signedIn users to like-toggle, this method will be denied for
  /// non-owners — the UI surfaces the error.
  Future<void> toggleCommentLike(String commentId) async {
    final uid = user?.uid ?? '';
    if (uid.isEmpty) throw StateError('Beğenmek için giriş yapmalısın.');
    final ref = _svc.comments.doc(commentId);
    await _svc.db.runTransaction((tx) async {
      final snap = await tx.get(ref);
      if (!snap.exists) return;
      final m = snap.data() ?? <String, dynamic>{};
      final liked = List<String>.from(((m['likedBy'] as List?) ?? const [])
          .map((e) => e.toString()));
      final hasLike = liked.contains(uid);
      if (hasLike) {
        liked.remove(uid);
      } else {
        liked.add(uid);
      }
      tx.update(ref, {
        'likedBy': liked,
        'likes': liked.length,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    });
  }

  // Community-side product creation goes through `product_requests` (see
  // `ProductRequestScreen`) and lands in the catalog only after admin
  // approval (`adminApproveRequest`). A direct `addProduct` here would
  // always be denied by the Firestore rules (`products` create requires
  // `isAdmin()`), so it was removed.

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
      // Reward the requester for a successful catalog contribution.
      // Admin context, so we can write the points field on someone else's
      // user doc (rules: `allow update: if isAdmin() || ...`).
      await _svc.userDoc(req.requestedByUid).set({
        'points': FieldValue.increment(PointsRules.addProduct),
      }, SetOptions(merge: true));
      await _svc
          .userNotifications(req.requestedByUid)
          .add({
        'title': 'Ürün talebin onaylandı',
        'body':
            '${req.name} artık katalogta. +${PointsRules.addProduct} PT kazandın.',
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

      // Reward the voter. We do not touch trust totals until the entry
      // actually reaches a terminal status (community_verified or rejected).
      // The previous "soft-alignment" rule made the first vote on any
      // entry guaranteed-correct (alignedSoft == true), which let users
      // farm trust by always voting first. Firestore rules enforce
      // trustVerifiedTotal + trustWrongTotal == trustTotalVotes, so all
      // three buckets stay untouched when no terminal verdict was reached.
      final reachedTerminal = next == PriceStatus.communityVerified ||
          next == PriceStatus.rejected;
      final alignedWithStatus = (next == PriceStatus.communityVerified && up) ||
          (next == PriceStatus.rejected && !up);
      tx.set(
        voterRef,
        {
          if (reachedTerminal) 'trustTotalVotes': FieldValue.increment(1),
          if (reachedTerminal && alignedWithStatus)
            'trustVerifiedTotal': FieldValue.increment(1),
          if (reachedTerminal && !alignedWithStatus)
            'trustWrongTotal': FieldValue.increment(1),
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

  /// Yeni omurgaya geçiş için lightweight cache: BasketTab compare panel
  /// `calculateRegionalBasketPricing` çağırınca son sonucu bu cache'e koyar
  /// (`updateBasketEstimateCache`). Sepet footer'ı bu cache'i kullanıp
  /// `priceGroups`-tabanlı tahmini toplam + tasarruf gösterir; legacy
  /// `priceHistory.lowestPrice` artık fallback.
  ///
  /// Tek-yönlü cache: BasketTab "Karşılaştır" görünümünde set edilir, sepet
  /// değişince stale olabilir; bu yüzden `_basketEstimateCacheKey`'i sepet
  /// imzasıyla mühürlüyoruz.
  List<BasketStoreEstimate> _basketSingleEstimateCache = const [];
  String _basketEstimateCacheKey = '';

  void updateBasketEstimateCache(BasketPricingResult result) {
    _basketSingleEstimateCache = result.singleMarketEstimates;
    _basketEstimateCacheKey = _currentBasketSignature();
    // Sessiz update — UI zaten cycle içinde notification alıyor.
  }

  String _currentBasketSignature() {
    final parts = <String>[
      cityName ?? '',
      districtName ?? '',
      ...cart.map((c) => '${c.product.id}:${c.quantity}'),
    ];
    return parts.join('|');
  }

  bool get _basketEstimateCacheFresh =>
      _basketEstimateCacheKey == _currentBasketSignature() &&
      _basketSingleEstimateCache.isNotEmpty;

  /// Tahmini sepet toplamı.
  /// Önce: priceGroups winner (en yüksek coverage'lı tek market) total.
  /// Yoksa fallback: legacy `priceHistory.lowestPrice * qty`.
  double get cartSubtotal {
    if (_basketEstimateCacheFresh) {
      return _basketSingleEstimateCache.first.estimatedTotal;
    }
    double total = 0;
    for (final c in cart) {
      total += (c.product.lowestPrice ?? 0) * c.quantity;
    }
    return total;
  }

  /// Tahmini tasarruf: en pahalı tek market vs en ucuz tek market farkı.
  /// Yeni yol: `_basketSingleEstimateCache` üzerinden. Fallback: legacy
  /// `priceHistory` per-store min/max.
  double get cartSavings {
    if (_basketEstimateCacheFresh &&
        _basketSingleEstimateCache.length >= 2) {
      final winner = _basketSingleEstimateCache.first.estimatedTotal;
      final worst = _basketSingleEstimateCache.last.estimatedTotal;
      final diff = worst - winner;
      return diff > 0 ? diff : 0;
    }
    double s = 0;
    for (final c in cart) {
      if (c.product.priceHistory.isEmpty) continue;
      final pricesByStore = <String, double>{};
      for (final e in c.product.priceHistory) {
        if (e.status == PriceStatus.rejected) continue;
        final key = e.store.trim().toLowerCase();
        if (key.isEmpty) continue;
        pricesByStore[key] = e.price;
      }
      if (pricesByStore.length < 2) continue;
      final high = pricesByStore.values.reduce((a, b) => a > b ? a : b);
      final low = pricesByStore.values.reduce((a, b) => a < b ? a : b);
      s += (high - low) * c.quantity;
    }
    return s;
  }

  int get cartItemCount => cart.fold(0, (a, c) => a + c.quantity);

  // The fields below (deliveryFee / redeemDiscount / cartTotal /
  // pointsEarnedForCart / setRedeemPoints / checkout) are scaffolding for
  // a real checkout flow that hasn't shipped yet — there is no checkout UI
  // anywhere in the app. They're kept so the future basket flow can wire
  // them without revisiting the data layer. Do NOT call them from UI code
  // until the checkout screen lands; the existing `BasketTab` only uses
  // `cartSubtotal` and `cartSavings`.

  @Deprecated('No checkout UI yet — see basket flow roadmap.')
  double get deliveryFee => cartSubtotal >= 250 || cart.isEmpty ? 0 : 14.9;

  @Deprecated('No checkout UI yet — see basket flow roadmap.')
  double get redeemDiscount => pointsToRedeem * PointsRules.pointValueTl;

  @Deprecated('No checkout UI yet — see basket flow roadmap.')
  double get cartTotal {
    // ignore: deprecated_member_use_from_same_package
    final t = cartSubtotal + deliveryFee - redeemDiscount;
    return t < 0 ? 0 : t;
  }

  @Deprecated('No checkout UI yet — see basket flow roadmap.')
  int get pointsEarnedForCart => (cartSubtotal ~/ 10); // 1 puan per ₺10

  @Deprecated('No checkout UI yet — see basket flow roadmap.')
  void setRedeemPoints(int p) {
    pointsToRedeem = p.clamp(0, points);
    notifyListeners();
  }

  @Deprecated('No checkout UI yet — see basket flow roadmap.')
  Future<void> checkout() async {
    if (user == null || cart.isEmpty) return;
    // ignore: deprecated_member_use_from_same_package
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
      // `productId` alanını da yazıyoruz: Cloud Function (`onProductPriceDrop`)
      // collectionGroup('productAlerts').where('productId', '==', id) ile
      // indexli sorgu yapabilsin, doc id eşleşmesi yerine. Eski full-scan
      // her ürün update'inde tüm alert dokümanlarını okuyordu.
      'productId': productId,
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
    final phoneRaw = phoneNumber?.trim();
    final hasPhone = phoneRaw != null && phoneRaw.isNotEmpty;
    await _svc.userDoc(user!.uid).set({
      'displayName': displayName.trim(),
      'username': username.trim(),
      'phoneNumber': hasPhone ? phoneRaw : FieldValue.delete(),
      if (profileImageUrl != null) 'profileImageUrl': profileImageUrl,
      if (profileImagePath != null) 'profileImagePath': profileImagePath,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> updateRegionSettings({
    required String cityName,
    String? districtName,
  }) async {
    if (user == null) {
      throw StateError('Aktif kullanıcı bulunamadı.');
    }
    // Always normalize against the canonical whitelist so that "İstanbul"
    // and "istanbul" never reach Firestore as two different cities.
    final canonicalCity = TurkeyLocations.canonicalCity(cityName);
    if (canonicalCity == null) {
      throw StateError(
          'Geçersiz il: "$cityName". Lütfen listeden seç.');
    }
    final canonicalDistrict =
        TurkeyLocations.canonicalDistrict(canonicalCity, districtName);
    if (districtName != null && districtName.trim().isNotEmpty &&
        canonicalDistrict == null) {
      throw StateError(
          'Geçersiz ilçe: "$districtName". Lütfen $canonicalCity ilçelerinden seç.');
    }
    await _svc.userDoc(user!.uid).set({
      'cityName': canonicalCity,
      if (canonicalDistrict != null)
        'district': canonicalDistrict
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
    bool? regionalDropPushEnabled,
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
          if (regionalDropPushEnabled != null)
            'regionalDropPushEnabled': regionalDropPushEnabled,
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
    // Drop the FCM token first so the just-signed-out account stops getting
    // push for this device. Best-effort — must not block logout.
    try {
      await MessagingService.instance.clearTokenForCurrentUser();
    } catch (_) {}
    await _productsSub?.cancel();
    await _authSub?.cancel();
    await _bannersSub?.cancel();
    await _storesSub?.cancel();
    await _categoriesSub?.cancel();
    await _userSub?.cancel();
    await _notificationsSub?.cancel();
    await _productAlertsSub?.cancel();
    await _productRequestsSub?.cancel();
    await _regionalPriceEntriesSub?.cancel();
    _productsSub = null;
    _authSub = null;
    _bannersSub = null;
    _storesSub = null;
    _categoriesSub = null;
    _userSub = null;
    _notificationsSub = null;
    _productAlertsSub = null;
    _productRequestsSub = null;
    _regionalPriceEntriesSub = null;
    products.clear();
    banners.clear();
    favorites.clear();
    notifications.clear();
    productAlerts.clear();
    cart.clear();
    _latestPriceEntryByProduct.clear();
    _homeScopedEntryByProduct.clear();
    points = 0;
    pointsToRedeem = 0;
    phoneNumber = null;
    cityName = null;
    districtName = null;
    activeHomeScope = HomePriceScope.nearby;
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
    _addPricePresetProductIds.clear();
    _addPricePresetChainId = null;
    _addPricePresetChainName = null;
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
    await _regionalPriceEntriesSub?.cancel();
    _productsSub = null;
    _authSub = null;
    _bannersSub = null;
    _storesSub = null;
    _categoriesSub = null;
    _userSub = null;
    _notificationsSub = null;
    _productAlertsSub = null;
    _productRequestsSub = null;
    _regionalPriceEntriesSub = null;
    products.clear();
    banners.clear();
    favorites.clear();
    notifications.clear();
    productAlerts.clear();
    cart.clear();
    _latestPriceEntryByProduct.clear();
    _homeScopedEntryByProduct.clear();
    points = 0;
    pointsToRedeem = 0;
    phoneNumber = null;
    cityName = null;
    districtName = null;
    activeHomeScope = HomePriceScope.nearby;
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
    _addPricePresetProductIds.clear();
    _addPricePresetChainId = null;
    _addPricePresetChainName = null;
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

  /// Use inside `build` methods. Subscribes the calling widget to rebuild
  /// when [AppState] notifies listeners.
  static AppState of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<AppStateScope>();
    assert(scope != null, 'AppStateScope not found in widget tree');
    return scope!.notifier!;
  }

  /// Use inside callbacks (`onTap`, async handlers, etc.) where you only
  /// need to invoke a method on [AppState] without subscribing the caller's
  /// element to future rebuilds. Registering a dependency in a callback that
  /// then unmounts the surrounding tree (e.g. via `Navigator.pushReplacement`)
  /// can trip the framework's `_dependents.isEmpty` assertion.
  static AppState read(BuildContext context) {
    final element =
        context.getElementForInheritedWidgetOfExactType<AppStateScope>();
    assert(element != null, 'AppStateScope not found in widget tree');
    return (element!.widget as AppStateScope).notifier!;
  }
}
