import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:in_app_purchase_android/in_app_purchase_android.dart';

import 'firebase_service.dart';

/// FiyatRadar Pro abonelik / IAP yönetimi.
///
/// Sorumluluk:
///   • Play Billing / StoreKit'ten ürün listesini çek (`queryProductDetails`).
///   • Kullanıcı satın alır → purchase stream üzerinden `pendingPurchases`
///     değerini Firestore'a yaz: `purchaseQueue/{uid}_{purchaseId}`. Cloud
///     Function tarafı Google Play Developer API ile doğrular ve
///     `users/{uid}.isPremium = true`, `premiumUntil = expiry` yazar.
///   • Restore akışı: kullanıcı yeni cihaz / yeniden kurulum durumunda
///     `restorePurchases()` çağırır; aynı queue'ya restore record yazılır.
///
/// İstemci ASLA `users/{uid}.isPremium`'u kendisi yazmaz — Firestore rules
/// `immutable('isPremium')` ile bunu zorlar (firestore.rules:147+). Tek
/// otorite Cloud Function (admin SDK).
///
/// `ChangeNotifier` — paywall ekranı ürün yükleme durumu değiştikçe
/// (loading → loaded / error) reactive olarak rebuild eder.
class PremiumService extends ChangeNotifier {
  PremiumService._();
  static final PremiumService instance = PremiumService._();

  /// Test-only seam: lets a fake subclass exist without touching Play Billing
  /// or Firebase. The plugin/Firebase handles below are `late` precisely so a
  /// subclass that overrides every public member never triggers their
  /// initializers.
  @visibleForTesting
  PremiumService.protected();

  /// Play Console + App Store Connect'te oluşturulan SKU id'leri.
  /// `fr_pro_monthly` aylık, `fr_pro_yearly` yıllık. Üretimde Console'da
  /// aynı id'lerle ürünleri tanımlamak gerek; SKU değişirse buradaki
  /// constant da güncellenmeli.
  static const String monthlySku = 'fr_pro_monthly';
  static const String yearlySku = 'fr_pro_yearly';
  static const Set<String> kProductIds = {monthlySku, yearlySku};

  /// Play Console'daki gerçek abonelik ürün id'si. Satın alma stream'i bu id
  /// (veya legacy aylık/yıllık SKU'lar) ile geldiğinde entitlement açılır.
  static const String premiumSku = 'fiyatradar_premium';

  /// `users/{uid}.isPremium = true` yazımını tetikleyen tanınan ürün id'leri.
  /// purchaseStream bu set'ten biriyle gelen `purchased`/`restored` event'inde
  /// premium açılır; başka bir productID gelirse entitlement YAZILMAZ.
  static const Set<String> kEntitlementProductIds = {
    premiumSku,
    monthlySku,
    yearlySku,
  };

  /// Entitlement yazıldıktan sonra çağrılan opsiyonel kanca. `main.dart` bunu
  /// `AppState.refreshPremiumEntitlement`'a bağlar; Firestore user-doc
  /// listener'ı zaten otomatik günceller, bu explicit refresh + log içindir.
  Future<void> Function()? onEntitlementChanged;

  late final InAppPurchase _iap = InAppPurchase.instance;
  late final FirebaseService _svc = FirebaseService.instance;

  StreamSubscription<List<PurchaseDetails>>? _purchaseSub;
  bool _initialized = false;
  List<ProductDetails> _availableProducts = const [];
  List<ProductDetails> get availableProducts => _availableProducts;

  /// `available` durumu app açılışından sonra `init()` döndürür. Üretimde
  /// Play Billing ile bağlanılamadığında (örn. iOS'ta cihaz, ya da Play
  /// Store yok edilmiş cihaz) UI Pro CTA'sını gizleyebilir.
  bool _available = false;
  bool get available => _available;

  /// Ürün listesi şu an Play Billing'ten yükleniyor mu.
  bool _loadingProducts = false;
  bool get loadingProducts => _loadingProducts;

  /// Sonuncu ürün yükleme denemesi tamamlandı mı (başarılı veya başarısız).
  /// `false` → daha hiç denenmedi (init henüz çağrılmadı / çalışıyor).
  bool _productsQueried = false;
  bool get productsQueried => _productsQueried;

  /// Ürün yükleme hatası (kullanıcıya gösterilebilir Türkçe mesaj). `null`
  /// → hata yok. Mağaza mevcut değilse de bu set edilir.
  String? _productsError;
  String? get productsError => _productsError;

  /// Aylık plan için Play Console'dan dönen ProductDetails, varsa.
  ProductDetails? get monthlyProduct {
    for (final p in _availableProducts) {
      if (p.id == monthlySku) return p;
    }
    return null;
  }

  /// Yıllık plan için Play Console'dan dönen ProductDetails, varsa.
  ProductDetails? get yearlyProduct {
    for (final p in _availableProducts) {
      if (p.id == yearlySku) return p;
    }
    return null;
  }

  /// Aylık planın YİNELENEN (deneme sonrası) fiyatı, lokalize string.
  String? get monthlyRecurringPrice => _recurringPrice(monthlyProduct);

  /// Yıllık planın YİNELENEN (deneme sonrası) fiyatı, lokalize string.
  String? get yearlyRecurringPrice => _recurringPrice(yearlyProduct);

  /// Abonelik için gösterilecek gerçek yinelenen fiyatı çıkarır.
  ///
  /// Android'de `ProductDetails.price`, teklifin ilk pricing phase'ini
  /// döndürür; ücretsiz deneme veya intro fiyatı varsa bu "₺0,00" / "Ücretsiz"
  /// olur ve kullanıcıyı yanıltır. Play Billing teklifinin pricing phase'leri
  /// sıralıdır ve sonuncusu daima sonsuz yinelenen (asıl abonelik) ücretidir;
  /// bu yüzden `subscriptionOfferDetails → pricingPhases → son phase` alınır.
  /// iOS / StoreKit'te intro offer ayrı tutulduğu için `.price` zaten yinelenen
  /// fiyattır → fallback.
  String? _recurringPrice(ProductDetails? product) {
    if (product == null) return null;
    if (product is! GooglePlayProductDetails) return product.price;
    final offers = product.productDetails.subscriptionOfferDetails;
    if (offers == null || offers.isEmpty) return product.price;
    final index = product.subscriptionIndex;
    final offer = (index != null && index >= 0 && index < offers.length)
        ? offers[index]
        : offers.first;
    final phases = offer.pricingPhases;
    if (phases.isEmpty) return product.price;
    final formatted = phases.last.formattedPrice;
    return formatted.trim().isEmpty ? product.price : formatted;
  }

  /// Satın alınabilir en az bir SKU var mı (CTA enable/disable için).
  ///
  /// `_available`'a AND'lemez: `reloadProducts` sırasında `isAvailable()`
  /// geçici olarak `false` dönerse (veya throw ederse) bu flag stale-false
  /// kalır ama daha önce yüklenmiş `_availableProducts` listesi durur. O
  /// durumda kullanıcı gerçek fiyatları görürken CTA'yı "Mağaza hazır değil"e
  /// düşürmek yanlış olur — gerçek sinyal ürünün yüklü olmasıdır.
  bool get hasPurchasableProducts => _availableProducts.isNotEmpty;

  /// IAP altyapısını ayağa kaldır + ürün listesini çek + purchase stream'i
  /// dinle. Idempotent — birden fazla `init()` çağrısı no-op.
  Future<void> init() async {
    if (_initialized) return;
    _initialized = true;
    _loadingProducts = true;
    notifyListeners();
    try {
      _available = await _iap.isAvailable();
    } catch (e) {
      debugPrint('PremiumService.isAvailable failed: $e');
      _available = false;
    }
    if (!_available) {
      _loadingProducts = false;
      _productsQueried = true;
      _productsError =
          'Mağaza bağlantısı kullanılamıyor. Play Store hesabını kontrol et.';
      notifyListeners();
      return;
    }

    // Listener'ı ürün sorgusundan ÖNCE bağla: kullanıcı satın aldığında sonuç
    // bu stream'den gelir; query gecikse/başarısız olsa bile dinleniyor olmalı.
    _ensurePurchaseListener();
    await _queryProducts();
  }

  /// purchaseStream listener'ını idempotent bağlar. `init()` ilk denemede
  /// mağazayı erişilemez bulup erken dönerse listener kurulmaz; sonradan
  /// `reloadProducts()` ürünleri yükleyebildiğinde bu çağrı listener'ı
  /// telafi eder — aksi halde satın alma tamamlanır ama uygulama duymaz.
  void _ensurePurchaseListener() {
    if (_purchaseSub != null) return;
    _purchaseSub = _iap.purchaseStream.listen(
      _handlePurchaseUpdates,
      onDone: () {
        _purchaseSub?.cancel();
        _purchaseSub = null;
      },
      onError: (Object e) =>
          debugPrint('PremiumService purchaseStream error: $e'),
    );
  }

  /// Ürün listesini yeniden Play Billing'ten çeker. Paywall ekranındaki
  /// "Tekrar dene" butonu bunu çağırır.
  Future<void> reloadProducts() async {
    if (!_initialized) {
      await init();
      return;
    }
    if (_loadingProducts) return;
    try {
      _available = await _iap.isAvailable();
    } catch (e) {
      debugPrint('PremiumService.isAvailable failed: $e');
      _available = false;
    }
    if (!_available) {
      _productsQueried = true;
      _productsError =
          'Mağaza bağlantısı kullanılamıyor. Play Store hesabını kontrol et.';
      notifyListeners();
      return;
    }
    // Mağaza artık erişilebilir; init erken dönmüş olsa bile listener'ı bağla.
    _ensurePurchaseListener();
    await _queryProducts();
  }

  Future<void> _queryProducts() async {
    _loadingProducts = true;
    _productsError = null;
    notifyListeners();
    try {
      final resp = await _iap.queryProductDetails(kProductIds);
      _availableProducts = resp.productDetails;
      debugPrint('🛍️ PAYWALL_QUERY: '
          'productDetails=${resp.productDetails.map((p) => "${p.id}=${p.price}").toList()} '
          'notFoundIDs=${resp.notFoundIDs} '
          'error=${resp.error}');
      if (resp.error != null) {
        debugPrint('PremiumService queryProductDetails error: ${resp.error}');
        _productsError =
            'Ürünler yüklenemedi: ${resp.error!.message}. İnternet bağlantını kontrol et.';
      } else if (resp.notFoundIDs.isNotEmpty &&
          _availableProducts.isEmpty) {
        debugPrint('Premium SKU bulunamadı: ${resp.notFoundIDs}');
        _productsError =
            'Abonelik ürünleri Play Store\'da henüz yayında değil. Birkaç dakika sonra tekrar dene.';
      } else if (resp.notFoundIDs.isNotEmpty) {
        debugPrint('Premium SKU kısmen bulunamadı: ${resp.notFoundIDs}');
      }
    } catch (e) {
      debugPrint('PremiumService.queryProductDetails failed: $e');
      _productsError =
          'Ürünler yüklenemedi, internet bağlantını kontrol et.';
    } finally {
      _loadingProducts = false;
      _productsQueried = true;
      notifyListeners();
    }
  }

  /// Aylık veya yıllık satın alma başlat. Auto-renewing subscription olarak
  /// yapılandırıldığı için `buyNonConsumable` kullanıyoruz; consumable
  /// olsaydı Play Billing acknowledge yapmazdı.
  Future<bool> purchase(ProductDetails product) async {
    // Gate on a loaded product, not the `_available` flag. Products only load
    // when the store was reachable; a later transient `isAvailable()` false
    // (reload race) must not block a checkout the user can see priced. Play
    // Billing surfaces its own error if the store is genuinely gone, and the
    // caller already try/catches.
    if (_availableProducts.isEmpty) return false;
    final purchaseParam = PurchaseParam(productDetails: product);
    return _iap.buyNonConsumable(purchaseParam: purchaseParam);
  }

  /// Yeni cihaz / yeniden kurulum sonrası kullanıcının var olan
  /// abonelik geçmişini geri yükler. Cloud Function aynı doğrulama
  /// pipeline'ında çalışacağı için sonuç user doc'a yansır.
  Future<void> restore() async {
    // Same rationale as purchase(): don't trust a possibly-stale `_available`.
    // If the store ever loaded products it is reachable; attempt the restore
    // and let restorePurchases surface any real failure. Only bail when there
    // is genuinely no store and nothing cached.
    if (!_available && _availableProducts.isEmpty) {
      debugPrint('PURCHASE_STREAM_EVENT: restore atlandı — mağaza yok ve '
          'önbellekte ürün yok');
      return;
    }
    debugPrint('PURCHASE_STREAM_EVENT: restorePurchases çağrıldı — mevcut '
        'abonelik stream üzerinden yeniden teslim edilecek');
    await _iap.restorePurchases();
  }

  Future<void> _handlePurchaseUpdates(List<PurchaseDetails> purchases) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    for (final p in purchases) {
      debugPrint('PURCHASE_STREAM_EVENT: status=${p.status.name} '
          'productID=${p.productID} '
          'pendingCompletePurchase=${p.pendingCompletePurchase}');
      if (uid == null) {
        // Oturum yoksa entitlement yazılamaz. Purchase'ı complete ETME —
        // pending kalsın ki oturum açıldığında stream tekrar teslim etsin.
        debugPrint('PURCHASE_STREAM_EVENT: signed-in uid yok, entitlement '
            'yazılamadı (${p.productID}) — purchase pending bırakıldı');
        continue;
      }
      switch (p.status) {
        case PurchaseStatus.pending:
          // Pending → premium AÇMA. Doğrulama bekleniyor.
          debugPrint('PURCHASE_STREAM_EVENT: pending → premium açılmadı '
              '(${p.productID})');
          break;
        case PurchaseStatus.purchased:
        case PurchaseStatus.restored:
          await _enqueueForServerVerification(uid, p);
          await _grantPremiumEntitlement(uid, p);
          if (p.pendingCompletePurchase) {
            await _iap.completePurchase(p);
          }
          break;
        case PurchaseStatus.error:
          // Hata → premium AÇMA.
          debugPrint('PURCHASE_STREAM_EVENT: error → premium açılmadı '
              '${p.error} (${p.productID})');
          if (p.pendingCompletePurchase) {
            await _iap.completePurchase(p);
          }
          break;
        case PurchaseStatus.canceled:
          // İptal → premium AÇMA.
          debugPrint('PURCHASE_STREAM_EVENT: canceled → premium açılmadı '
              '(${p.productID})');
          if (p.pendingCompletePurchase) {
            await _iap.completePurchase(p);
          }
          break;
      }
    }
  }

  /// İstemci tarafı premium entitlement yazımı. `purchased`/`restored` event'i
  /// tanınan bir abonelik ürünü için geldiğinde `users/{uid}` dokümanına
  /// premium alanlarını merge eder. Firestore rules `hasSafePremiumMutation`
  /// ile bu alanların tip güvenliğini zorlar.
  ///
  /// NOT: Bu, sunucu tarafı (Cloud Function) doğrulamanın yerine geçen geçici
  /// minimum istemci-taraflı entitlement'tır.
  Future<void> _grantPremiumEntitlement(String uid, PurchaseDetails p) async {
    final productId = p.productID;
    if (!kEntitlementProductIds.contains(productId)) {
      debugPrint('PREMIUM_ENTITLEMENT_WRITING: atlandı — productID=$productId '
          'tanınan premium ürünü değil (uid=$uid)');
      return;
    }
    debugPrint('PREMIUM_ENTITLEMENT_WRITING: uid=$uid productID=$productId');
    try {
      await _svc.userDoc(uid).set({
        'isPremium': true,
        'premiumSource': 'google_play',
        'premiumProductId': productId,
        'premiumPurchaseId': p.purchaseID ?? '',
        'premiumPurchaseToken': p.verificationData.serverVerificationData,
        'premiumUpdatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      debugPrint('PREMIUM_ENTITLEMENT_WRITTEN: uid=$uid productID=$productId');
    } catch (e) {
      debugPrint('PREMIUM_ENTITLEMENT_WRITE_FAILED: uid=$uid '
          'productID=$productId error=$e');
      return;
    }
    // Premium provider'ı tazele. Firestore user-doc listener zaten otomatik
    // günceller; bu explicit refresh + log (sessiz return yok).
    try {
      await onEntitlementChanged?.call();
      debugPrint('PREMIUM_PROVIDER_REFRESHED: uid=$uid');
    } catch (e) {
      debugPrint('PREMIUM_PROVIDER_REFRESHED: başarısız → $e');
    }
  }

  /// Cloud Function tarafına doğrulanması için pending kuyruğa yazıyoruz.
  /// Function Play Developer API ile token doğrular, sonra
  /// `users/{uid}.isPremium = true` yazar. Doc id deterministik:
  /// `${uid}_${productId}_${purchaseId}` — aynı transaction tekrar gelirse
  /// idempotent kalsın.
  Future<void> _enqueueForServerVerification(
    String uid,
    PurchaseDetails p,
  ) async {
    final productId = p.productID;
    final purchaseId = p.purchaseID ?? '';
    final docId = '${uid}_${productId}_${purchaseId.isNotEmpty ? purchaseId : DateTime.now().millisecondsSinceEpoch}';
    try {
      await _svc.db
          .collection('purchaseQueue')
          .doc(docId)
          .set({
        'userId': uid,
        'productId': productId,
        'purchaseId': purchaseId,
        'platform': defaultTargetPlatform == TargetPlatform.iOS
            ? 'ios'
            : 'android',
        // Play Billing için verificationData.serverVerificationData purchase
        // token'ını içeriyor; iOS için receipt data. Function tarafı
        // platforma göre farklı doğrulama yapar.
        'verificationData': p.verificationData.serverVerificationData,
        'transactionDate': p.transactionDate,
        'status': p.status.name,
        'createdAt': FieldValue.serverTimestamp(),
        'consumed': false,
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('purchaseQueue write failed: $e');
    }
  }

  @override
  Future<void> dispose() async {
    await _purchaseSub?.cancel();
    _purchaseSub = null;
    _initialized = false;
    super.dispose();
  }
}

/// Premium snapshot — `AppState.premium` getter'ından dönen value type.
class PremiumStatus {
  final bool isActive;
  final DateTime? until;
  final String? plan;

  const PremiumStatus({
    required this.isActive,
    required this.until,
    required this.plan,
  });

  static const inactive =
      PremiumStatus(isActive: false, until: null, plan: null);

  String get planLabel {
    if (!isActive) return 'Ücretsiz';
    if (plan == PremiumService.yearlySku) return 'Pro · Yıllık';
    if (plan == PremiumService.monthlySku) return 'Pro · Aylık';
    return 'Pro';
  }

  Duration? get remaining {
    if (!isActive || until == null) return null;
    final now = DateTime.now();
    final diff = until!.difference(now);
    return diff.isNegative ? Duration.zero : diff;
  }
}
