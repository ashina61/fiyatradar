import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:in_app_purchase_android/in_app_purchase_android.dart';

import 'firebase_service.dart';

/// Paywall'ın bir satın alma başlattıktan sonra beklediği nihai sonuç.
///
/// Premium entitlement artık YALNIZ sunucu (`verifyPurchase` Cloud Function,
/// Admin SDK) tarafından yazıldığı için, istemci "satın alındı" demekle
/// premium'u açmaz; sunucunun `users/{uid}.isPremium`'u yazmasını bekler ve
/// sonucu buradaki değerlerle UI'ya bildirir.
enum PremiumPurchaseOutcome {
  /// `verifyPurchase` entitlement'ı yazdı — premium aktif.
  verified,

  /// Satın alma alındı ama sunucu doğrulaması zaman aşımına uğradı veya
  /// başarısız oldu (Play API hatası / inactive abonelik). Premium açılmadı.
  verificationFailed,

  /// Play Billing satın alma hatası döndürdü.
  error,

  /// Kullanıcı satın almayı iptal etti.
  canceled,
}

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
/// İstemci ASLA `users/{uid}.isPremium` (veya premiumUntil / premiumPlan /
/// premiumSource / premiumProductId / premiumPurchaseId / premiumPurchaseToken
/// / premiumUpdatedAt) yazmaz — Firestore rules bu alanları client mutation'a
/// kapatır (`hasNoImmutableUserChanges` + writable-key whitelist'inden hariç).
/// Tek otorite `verifyPurchase` Cloud Function'ı (Admin SDK; rules'ı bypass
/// eder). Client yalnız `purchaseQueue`'ya yazıp doğrulamayı tetikler.
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

  /// `restore()` çağrısı sırasında tanınan bir abonelik event'i (restored /
  /// purchased) gelene kadar bekleyen completer. Event geldiğinde
  /// `_handlePurchaseUpdates` bunu `true` ile tamamlar (mağazada abonelik var
  /// sinyali); 10 sn içinde hiçbir event gelmezse `restore()` `false` döner ve
  /// UI "aktif abonelik bulunamadı" gösterir. Restore akışı dışında `null`.
  Completer<bool>? _restoreCompleter;

  /// `purchase()` ile başlatılan akışın paywall'a döndürülecek sonucu. Yeni
  /// satın almada sıfırlanır; `purchased`/`error`/`canceled` event'i geldiğinde
  /// `_handlePurchaseUpdates` uygun [PremiumPurchaseOutcome] ile tamamlar.
  /// Paywall `awaitPurchaseOutcome()` ile bekler. Satın alma akışı dışında
  /// `null`.
  Completer<PremiumPurchaseOutcome>? _purchaseOutcomeCompleter;

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
    // Güvenlik duruşu: premium entitlement alanları Firestore rules ile client
    // mutation'a kapalı; yalnız verifyPurchase Cloud Function (Admin SDK) yazar.
    debugPrint('FIRESTORE_RULES_PREMIUM_FIELDS_IMMUTABLE: client premium '
        'yazımı kapalı — entitlement yalnız verifyPurchase tarafından yazılır');
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
    // Yeni satın alma için sonuç completer'ını hazırla. Paywall, bu çağrı true
    // dönünce `awaitPurchaseOutcome()` ile sonucu bekler; sonuç purchaseStream
    // event'i + sunucu doğrulaması tamamlanınca gelir.
    _purchaseOutcomeCompleter = Completer<PremiumPurchaseOutcome>();
    final purchaseParam = PurchaseParam(productDetails: product);
    return _iap.buyNonConsumable(purchaseParam: purchaseParam);
  }

  /// Paywall, `purchase()` true dönünce bunu await eder. `purchased` /
  /// `error` / `canceled` event'i (purchased için ayrıca sunucu entitlement
  /// yazımı) tamamlanana kadar — ya da [timeout] dolana kadar — bekler.
  ///
  /// Premium artık client tarafından YAZILMADIĞI için `verified` sonucu,
  /// `users/{uid}.isPremium`'un sunucu (verifyPurchase) tarafından gerçekten
  /// yazıldığını ifade eder.
  Future<PremiumPurchaseOutcome> awaitPurchaseOutcome({
    Duration timeout = const Duration(seconds: 120),
  }) {
    final completer = _purchaseOutcomeCompleter;
    if (completer == null) {
      return Future.value(PremiumPurchaseOutcome.verificationFailed);
    }
    return Future.any<PremiumPurchaseOutcome>([
      completer.future,
      Future<PremiumPurchaseOutcome>.delayed(
          timeout, () => PremiumPurchaseOutcome.verificationFailed),
    ]);
  }

  void _completePurchaseOutcome(PremiumPurchaseOutcome outcome) {
    final c = _purchaseOutcomeCompleter;
    if (c != null && !c.isCompleted) c.complete(outcome);
  }

  /// `verifyPurchase` Cloud Function (Admin SDK) `users/{uid}.isPremium`'u
  /// yazana kadar bekler. İstemci ARTIK premium yazmadığı için entitlement'ın
  /// tek kaynağı budur. [timeout] içinde `isPremium == true` gözlenirse `true`,
  /// aksi halde `false` döner (premium sonradan listener ile yine yansıyabilir,
  /// ama UI'ya "doğrulanamadı" geri bildirimi için bu sınır gerekir).
  Future<bool> _awaitServerEntitlement(
    String uid, {
    Duration timeout = const Duration(seconds: 45),
  }) async {
    try {
      final snap = await _svc.userDoc(uid).get();
      if ((snap.data()?['isPremium'] as bool?) == true) return true;
    } catch (e) {
      debugPrint('VERIFY_PURCHASE: ön kontrol okunamadı → $e');
    }
    final completer = Completer<bool>();
    final sub = _svc.userDoc(uid).snapshots().listen(
      (snap) {
        if ((snap.data()?['isPremium'] as bool?) == true &&
            !completer.isCompleted) {
          completer.complete(true);
        }
      },
      onError: (Object e) =>
          debugPrint('VERIFY_PURCHASE: user-doc listen hatası → $e'),
    );
    final result = await Future.any<bool>([
      completer.future,
      Future<bool>.delayed(timeout, () => false),
    ]);
    await sub.cancel();
    return result;
  }

  /// Yeni cihaz / yeniden kurulum sonrası kullanıcının var olan
  /// abonelik geçmişini geri yükler. Cloud Function aynı doğrulama
  /// pipeline'ında çalışacağı için sonuç user doc'a yansır.
  ///
  /// Dönüş: 10 sn içinde tanınan bir abonelik event'i (restored / purchased)
  /// gelip premium açıldıysa `true`, gelmediyse `false`. UI bu değere göre
  /// "geri yüklendi" veya "aktif abonelik bulunamadı" mesajını gösterir
  /// (sessiz return yok).
  Future<bool> restore() async {
    debugPrint('🔄 RESTORE_PURCHASES_CALLED');
    // Same rationale as purchase(): don't trust a possibly-stale `_available`.
    // If the store ever loaded products it is reachable; attempt the restore
    // and let restorePurchases surface any real failure. Only bail when there
    // is genuinely no store and nothing cached.
    if (!_available && _availableProducts.isEmpty) {
      debugPrint('PURCHASE_STREAM_EVENT: restore atlandı — mağaza yok ve '
          'önbellekte ürün yok');
      return false;
    }
    // Listener restorePurchases çağrılmadan ÖNCE aktif olmalı: restored
    // event'leri bu stream'den gelir. init erken dönmüş olabilir, telafi et.
    _ensurePurchaseListener();
    final completer = Completer<bool>();
    _restoreCompleter = completer;
    debugPrint('PURCHASE_STREAM_EVENT: restorePurchases çağrıldı — mevcut '
        'abonelik stream üzerinden yeniden teslim edilecek');
    try {
      await _iap.restorePurchases();
    } catch (e) {
      debugPrint('RESTORE_PURCHASES_CALLED: restorePurchases hata → $e');
    }
    // 10 sn içinde tanınan bir abonelik event'i gelmezse false dön.
    final restored = await Future.any<bool>([
      completer.future,
      Future<bool>.delayed(const Duration(seconds: 10), () => false),
    ]);
    if (identical(_restoreCompleter, completer)) _restoreCompleter = null;
    return restored;
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
          await _handleVerifiedDelivery(uid, p);
          if (p.pendingCompletePurchase) {
            await _iap.completePurchase(p);
          }
          break;
        case PurchaseStatus.error:
          // Hata → premium AÇMA.
          debugPrint('PURCHASE_STREAM_EVENT: error → premium açılmadı '
              '${p.error} (${p.productID})');
          _completePurchaseOutcome(PremiumPurchaseOutcome.error);
          if (p.pendingCompletePurchase) {
            await _iap.completePurchase(p);
          }
          break;
        case PurchaseStatus.canceled:
          // İptal → premium AÇMA.
          debugPrint('PURCHASE_STREAM_EVENT: canceled → premium açılmadı '
              '(${p.productID})');
          _completePurchaseOutcome(PremiumPurchaseOutcome.canceled);
          if (p.pendingCompletePurchase) {
            await _iap.completePurchase(p);
          }
          break;
      }
    }
  }

  /// `purchased` VE `restored` event'leri için tek merkezi akış. İstemci
  /// premium ALANLARINI ARTIK YAZMAZ — yalnız `purchaseQueue`'ya yazarak
  /// `verifyPurchase` Cloud Function'ını (Admin SDK + Google Play Developer
  /// API) tetikler ve sunucunun `users/{uid}.isPremium` yazmasını bekler.
  /// Firestore rules premium alanlarını client mutation'a kapattığı için
  /// (FIRESTORE_RULES_PREMIUM_FIELDS_IMMUTABLE) tek otorite budur.
  Future<void> _handleVerifiedDelivery(String uid, PurchaseDetails p) async {
    final isRestore = p.status == PurchaseStatus.restored;
    final productId = p.productID;
    if (isRestore) {
      debugPrint('RESTORED_PURCHASE_FOUND: productID=$productId '
          'purchaseID=${p.purchaseID}');
      debugPrint('RESTORE_VERIFY_PURCHASE_CALLING: uid=$uid '
          'productID=$productId');
    } else {
      debugPrint('VERIFY_PURCHASE_CALLING: uid=$uid productID=$productId');
    }

    final recognized = kEntitlementProductIds.contains(productId);
    if (!recognized) {
      debugPrint('VERIFY_PURCHASE_FAILED: tanınmayan ürün productID=$productId '
          '(uid=$uid) — entitlement yazılmadı');
      if (!isRestore) {
        _completePurchaseOutcome(PremiumPurchaseOutcome.verificationFailed);
      }
      return;
    }

    // Sunucu doğrulaması için kuyruğa yaz → verifyPurchase tetiklenir.
    await _enqueueForServerVerification(uid, p);
    debugPrint('CLIENT_PREMIUM_WRITE_BLOCKED_REMOVED: uid=$uid '
        'productID=$productId (premium yalnız verifyPurchase tarafından yazılır)');

    // Restore akışı: tanınan event = "mağazada abonelik var" sinyali. UI'nın
    // "kontrol ediliyor" beklemesini bitir; gerçek premium sunucu yazınca
    // listener üzerinden yansır.
    if (isRestore &&
        _restoreCompleter != null &&
        !_restoreCompleter!.isCompleted) {
      _restoreCompleter!.complete(true);
    }

    // verifyPurchase (Admin SDK) user-doc'a isPremium yazana kadar bekle.
    final verified = await _awaitServerEntitlement(uid);
    if (verified) {
      debugPrint(isRestore
          ? 'VERIFY_PURCHASE_SUCCESS_FROM_RESTORE: uid=$uid productID=$productId'
          : 'VERIFY_PURCHASE_SUCCESS: uid=$uid productID=$productId');
      try {
        await onEntitlementChanged?.call();
        debugPrint('PREMIUM_PROVIDER_REFRESHED_AFTER_VERIFY: uid=$uid');
      } catch (e) {
        debugPrint('PREMIUM_PROVIDER_REFRESHED_AFTER_VERIFY: başarısız → $e');
      }
      if (!isRestore) {
        _completePurchaseOutcome(PremiumPurchaseOutcome.verified);
      }
    } else {
      debugPrint('VERIFY_PURCHASE_FAILED: uid=$uid productID=$productId '
          '(sunucu doğrulaması zaman aşımı/başarısız)');
      if (!isRestore) {
        _completePurchaseOutcome(PremiumPurchaseOutcome.verificationFailed);
      }
    }
  }

  /// Cloud Function tarafına doğrulanması için pending kuyruğa yazıyoruz.
  /// Function Play Developer API ile token doğrular, sonra
  /// `users/{uid}.isPremium = true` yazar.
  ///
  /// Doc id: `purchased` için deterministik (`${uid}_${productId}_${purchaseId}`)
  /// — aynı satın alma tekrar teslim edilirse fazladan API çağrısı olmasın.
  /// `restored` için ise timestamp ekli BENZERSIZ id kullanırız: aksi halde
  /// orijinal satın almanın doc'uyla çakışır, `set(merge)` bir UPDATE'e döner
  /// ve purchaseQueue update kuralı (yalnız admin) restore'u sessizce reddeder
  /// → verifyPurchase tetiklenmez. Benzersiz id her restore'da `onDocumentCreated`
  /// trigger'ını garanti eder (Function idempotent; premium'u aynı şekilde yazar).
  Future<void> _enqueueForServerVerification(
    String uid,
    PurchaseDetails p,
  ) async {
    final productId = p.productID;
    final purchaseId = p.purchaseID ?? '';
    final isRestore = p.status == PurchaseStatus.restored;
    final suffix = (purchaseId.isNotEmpty && !isRestore)
        ? purchaseId
        : '${purchaseId.isNotEmpty ? '${purchaseId}_' : ''}${DateTime.now().millisecondsSinceEpoch}';
    final docId = '${uid}_${productId}_$suffix';
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
